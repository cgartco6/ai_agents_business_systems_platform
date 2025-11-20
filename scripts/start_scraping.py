#!/usr/bin/env python3
import asyncio
import logging
from src.scraping.scraping_manager import ComprehensiveScrapingManager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('ScrapingService')

async def main():
    """Start the comprehensive scraping service"""
    
    logger.info("🚀 Starting AI Scraping System...")
    
    # Initialize scraping manager
    scraping_manager = ComprehensiveScrapingManager()
    
    # Initial scrape
    logger.info("Running initial comprehensive scrape...")
    await scraping_manager.run_comprehensive_scrape()
    
    # Start scheduled scraping
    logger.info("Starting scheduled scraping (every 60 minutes)...")
    await scraping_manager.schedule_scraping(interval_minutes=60)

if __name__ == '__main__':
    asyncio.run(main())
