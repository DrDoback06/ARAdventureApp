import { Request, Response, NextFunction } from 'express';
import { RateLimiterMemory } from 'rate-limiter-flexible';

// Create rate limiters for different endpoints
const rateLimiters = {
  // General API rate limiter - 100 requests per minute
  general: new RateLimiterMemory({
    keyGenerator: (req: Request) => req.ip,
    points: 100, // Number of requests
    duration: 60, // Per 60 seconds
  }),

  // Authentication endpoints - 20 requests per minute
  auth: new RateLimiterMemory({
    keyGenerator: (req: Request) => req.ip,
    points: 20,
    duration: 60,
  }),

  // Battle actions - 300 requests per minute (for real-time gameplay)
  battle: new RateLimiterMemory({
    keyGenerator: (req: Request) => req.ip,
    points: 300,
    duration: 60,
  }),

  // Social actions - 50 requests per minute
  social: new RateLimiterMemory({
    keyGenerator: (req: Request) => req.ip,
    points: 50,
    duration: 60,
  }),

  // Heavy operations - 10 requests per minute
  heavy: new RateLimiterMemory({
    keyGenerator: (req: Request) => req.ip,
    points: 10,
    duration: 60,
  }),
};

/**
 * General rate limiting middleware
 */
export const rateLimitMiddleware = async (
  req: Request, 
  res: Response, 
  next: NextFunction
): Promise<void> => {
  try {
    await rateLimiters.general.consume(req.ip);
    next();
  } catch (rejRes) {
    const totalHitsPerWindow = rejRes.totalHits || 0;
    const resetTime = rejRes.msBeforeNext || 0;
    
    res.status(429).json({
      error: 'Too Many Requests',
      message: 'Rate limit exceeded',
      retryAfter: Math.round(resetTime / 1000),
      totalRequests: totalHitsPerWindow
    });
  }
};

/**
 * Create a rate limiter for specific endpoint types
 */
export const createRateLimiter = (type: keyof typeof rateLimiters) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await rateLimiters[type].consume(req.ip);
      next();
    } catch (rejRes) {
      const resetTime = rejRes.msBeforeNext || 0;
      
      res.status(429).json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded for ${type} operations`,
        retryAfter: Math.round(resetTime / 1000)
      });
    }
  };
};

/**
 * User-specific rate limiter (requires authentication)
 */
export const createUserRateLimiter = (points: number, duration: number) => {
  const limiter = new RateLimiterMemory({
    keyGenerator: (req: any) => req.userId || req.ip,
    points,
    duration,
  });

  return async (req: any, res: Response, next: NextFunction): Promise<void> => {
    try {
      await limiter.consume(req.userId || req.ip);
      next();
    } catch (rejRes) {
      const resetTime = rejRes.msBeforeNext || 0;
      
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'User rate limit exceeded',
        retryAfter: Math.round(resetTime / 1000)
      });
    }
  };
};