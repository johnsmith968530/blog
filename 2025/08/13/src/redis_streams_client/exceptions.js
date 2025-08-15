export class JobError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JobError';
  }
}
