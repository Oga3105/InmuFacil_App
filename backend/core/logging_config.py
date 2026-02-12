"""
Centralized Logging Configuration for InmuFácil Backend

This module provides a consistent logging setup across the entire application.
All modules should use this instead of print() statements.

Usage:
    from backend.core.logging_config import get_logger
    
    logger = get_logger(__name__)
    logger.info("Application started")
    logger.error("Error occurred", exc_info=True)
"""

import logging
import sys
from pathlib import Path

# Log file path
LOG_FILE = Path(__file__).parent.parent.parent / "inmufacil.log"


def setup_logging(level=logging.INFO):
    """
    Configure logging for the entire application.
    
    Args:
        level: Logging level (default: INFO)
    """
    # Create formatter with emojis for better readability
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Console handler (stdout)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    
    # File handler
    file_handler = logging.FileHandler(LOG_FILE, encoding='utf-8')
    file_handler.setFormatter(formatter)
    
    # Root logger configuration
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.addHandler(console_handler)
    root_logger.addHandler(file_handler)
    
    # Suppress noisy third-party loggers
    logging.getLogger('urllib3').setLevel(logging.WARNING)
    logging.getLogger('sqlalchemy').setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger instance for a module.
    
    Args:
        name: Module name (use __name__)
        
    Returns:
        Logger instance
        
    Example:
        logger = get_logger(__name__)
        logger.info("🚀 Server started")
    """
    return logging.getLogger(name)


# Initialize logging on module import
setup_logging()
