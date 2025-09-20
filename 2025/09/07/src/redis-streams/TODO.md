# Potential Features for Common Library

## Consider Expanding Common Infrastructure

The redis-streams library currently provides base functionality for MCP servers that interact with Redis Streams workers. Analysis of existing implementations (openrouter-stream, stardate-stream, cpdoi-stream, etc.) reveals opportunities for further abstraction and standardization.

### Configuration Management

#### Stream Naming Convention Helper
- Currently each server manually defines stream names (e.g. 'service:requests', 'service:responses')
- Could provide a StreamNaming class/utility:
  ```typescript
  class StreamNaming {
    constructor(serviceName: string) {
      this.requestStream = `${serviceName}:requests`;
      this.responseStream = `${serviceName}:responses`;
      this.timeoutKey = `${serviceName}:timeout`;
    }
  }
  ```
- Benefits:
  - Ensures consistent naming across services
  - Reduces chance of typos
  - Makes refactoring stream names easier
  - Could add validation/sanitization of service names

#### Logging Infrastructure
- Common logging directory structure setup
- Standardized log rotation policies
- Shared log format definitions
- Common log analysis utilities

### Tool Definition Framework

#### Schema Builder Utilities
- Many tools have similar JSON Schema patterns
- Could provide builders for common schema types:
  ```typescript
  class SchemaBuilder {
    static pathParameter(description: string): object
    static timestampParameter(description: string): object
    static enumParameter(values: string[], description: string): object
    // etc.
  }
  ```
- Benefits:
  - Reduces boilerplate in tool definitions
  - Ensures consistent parameter definitions
  - Makes schema updates easier to propagate

#### Common Parameter Types
- Standard definitions for frequently used parameters:
  - File paths
  - Timestamps/dates
  - URLs
  - Logging flags
  - Format specifiers
- Benefits:
  - Consistency across tools
  - Shared validation logic
  - Better type safety

### Error Handling

#### Error Type System
- Standardized error categories
- Common error response formatting
- Shared retry logic for transient failures
- Benefits:
  - Consistent error handling across services
  - Better error reporting
  - Simplified debugging

### Testing Support

#### Test Utilities
- Mock Redis Stream interfaces
- Test data generators
- Common test patterns
- Benefits:
  - Easier testing setup
  - More consistent test coverage
  - Shared test infrastructure

### Monitoring and Metrics

#### Common Metrics Collection
- Standard performance metrics
- Queue length monitoring
- Response time tracking
- Benefits:
  - Consistent monitoring across services
  - Easier system-wide analysis
  - Common dashboard configurations

### Open Questions

- How to balance abstraction vs. flexibility?
- Should the library provide default implementations or just interfaces?
- How to handle version compatibility across services?
- What level of customization should be allowed?
- How to maintain backward compatibility while adding features?

For now, this is just a proposal to consider. The existing implementations can serve as reference points for identifying which patterns are truly common and which need to remain service-specific.
