class JobError(Exception):
    """Exception raised for errors in the job processing."""
    def __init__(self, message):
        self.message = message
        super().__init__(self.message)
