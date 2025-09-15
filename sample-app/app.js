const express = require('express');
const winston = require('winston');
const LokiTransport = require('winston-loki');
const promClient = require('prom-client');
const { trace, SpanStatusCode } = require('@opentelemetry/api');
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { SimpleSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

// -------------------- OpenTelemetry Setup -------------------- //

// Tracing
const tracerProvider = new NodeTracerProvider();
const traceExporter = new OTLPTraceExporter({
  url: 'http://tempo:4318/v1/traces'
});
tracerProvider.addSpanProcessor(new SimpleSpanProcessor(traceExporter));
tracerProvider.register();

// Get tracer instance
const tracer = trace.getTracer('dslm-sample-app', '1.0.0');

// -------------------- Logging (Winston + Loki) -------------------- //

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new LokiTransport({
      host: 'http://loki:3100',
      labels: { app: 'dslm-sample-app', job: 'sample-service' },
      json: true,
      format: winston.format.json(),
      replaceTimestamp: true,
      onConnectionError: (err) => console.error('Loki connection error:', err)
    })
  ]
});

// -------------------- Prometheus Metrics -------------------- //

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const requestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register]
});

const activeConnections = new promClient.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register]
});

// -------------------- Express Application -------------------- //

const app = express();
const PORT = process.env.PORT || 3001;

// Request tracking middleware
app.use((req, res, next) => {
  const start = Date.now();
  activeConnections.inc();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestsTotal.inc({ method: req.method, route: req.route?.path || req.path, status_code: res.statusCode });
    requestDuration.observe({ method: req.method, route: req.route?.path || req.path }, duration);
    activeConnections.dec();

    logger.info('HTTP Request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: duration,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
  });

  next();
});

app.use(express.json());

// Routes
app.get('/', (req, res) => {
  const span = tracer.startSpan('handle_homepage');
  span.setAttribute('user.id', 'anonymous');
  span.setAttribute('page.type', 'homepage');

  logger.info('Homepage accessed', { userId: 'anonymous', timestamp: new Date().toISOString() });

  setTimeout(() => {
    span.setStatus({ code: SpanStatusCode.OK });
    span.end();
    res.json({
      message: 'Welcome to DSLM Sample App!',
      timestamp: new Date().toISOString(),
      version: '1.0.0'
    });
  }, Math.random() * 100);
});

app.get('/api/health', (req, res) => {
  const span = tracer.startSpan('health_check');
  span.setAttribute('health.status', 'ok');

  logger.info('Health check performed', {
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });

  span.end();
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/work', (req, res) => {
  const span = tracer.startSpan('do_work');
  span.setAttribute('work.type', 'computation');
  span.setAttribute('work.complexity', 'medium');

  const workSpan = tracer.startSpan('computation', { parent: span });
  workSpan.setAttribute('operation', 'fibonacci');

  const result = fibonacci(25);

  workSpan.setAttribute('result.size', result.toString().length);
  workSpan.end();

  logger.info('Work completed', {
    operation: 'fibonacci',
    input: 25,
    result: result
  });

  span.end();
  res.json({
    operation: 'fibonacci',
    input: 25,
    result: result,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/error', (req, res) => {
  const span = tracer.startSpan('simulate_error');
  span.setAttribute('error.type', 'simulated');
  span.setAttribute('error.severity', 'medium');

  const error = new Error('Simulated error for testing');
  logger.error('Simulated error occurred', {
    error: error.message,
    stack: error.stack,
    userId: 'test-user',
    endpoint: '/api/error'
  });

  span.recordException(error);
  span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
  span.end();

  res.status(500).json({
    error: 'Internal Server Error',
    message: 'This is a simulated error for testing purposes',
    timestamp: new Date().toISOString()
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    const metrics = await register.metrics();
    res.set('Content-Type', register.contentType);
    res.end(metrics);
  } catch (ex) {
    res.status(500).end(ex);
  }
});

// Fibonacci function
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Periodic activity
function generatePeriodicActivity() {
  const activities = [
    () => {
      const span = tracer.startSpan('periodic_health_check');
      logger.info('Periodic health check', { status: 'ok' });
      span.end();
    },
    () => {
      const span = tracer.startSpan('periodic_metric_collection');
      logger.warn('High memory usage detected', { usage: Math.random() * 100 });
      span.end();
    },
    () => {
      const span = tracer.startSpan('periodic_cleanup');
      logger.info('Cleanup completed', { itemsProcessed: Math.floor(Math.random() * 100) });
      span.end();
    }
  ];
  activities[Math.floor(Math.random() * activities.length)]();
}
setInterval(generatePeriodicActivity, 30000);

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  tracerProvider.shutdown();
});
process.on('SIGINT', () => {
  logger.info('Received SIGINT, shutting down gracefully');
  tracerProvider.shutdown();
});

// Start server
app.listen(PORT, () => {
  logger.info('DSLM Sample App started', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });

  console.log(`🚀 DSLM Sample App running on port ${PORT}`);
  console.log(`📊 Metrics available at http://localhost:${PORT}/metrics`);
  console.log(`🔍 Health check at http://localhost:${PORT}/api/health`);
  console.log(`🏠 Homepage at http://localhost:${PORT}/`);
});
