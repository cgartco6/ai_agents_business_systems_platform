import asyncio
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import json
from .base_scraper import ScrapingConfig
from .job_scrapers import JobScrapingManager, LinkedInScraper, IndeedScraper
from .data_scrapers import FinancialDataScraper, RealEstateScraper, WebDataScraper
from .odds_scrapers import BettingOddsScraper, TeamDataScraper, APIScraper

class ComprehensiveScrapingManager:
    def __init__(self):
        self.config = ScrapingConfig(
            max_concurrent=10,
            request_delay=1.0,
            timeout=30,
            retry_attempts=3
        )
        
        # Initialize all scrapers
        self.scrapers = {
            'jobs': JobScrapingManager(self.config),
            'financial': FinancialDataScraper(self.config),
            'real_estate': RealEstateScraper(self.config),
            'odds': BettingOddsScraper(self.config),
            'teams': TeamDataScraper(self.config),
            'api': APIScraper(self.config),
            'web': WebDataScraper(self.config)
        }
        
        self.scraping_history = []
    
    async def run_comprehensive_scrape(self, targets: Dict[str, Any] = None) -> Dict[str, Any]:
        """Run comprehensive scraping across all categories"""
        
        if targets is None:
            targets = {
                'jobs': {'keywords': ['python', 'ai', 'data scientist']},
                'financial': {'data_types': ['crypto', 'forex']},
                'odds': {'sports': ['soccer', 'rugby']},
                'teams': {'sports': ['soccer', 'rugby']}
            }
        
        results = {}
        
        for category, params in targets.items():
            if category in self.scrapers:
                self.logger.info(f"Starting {category} scraping...")
                
                try:
                    if category == 'jobs':
                        scraper_results = await self.scrapers[category].scrape_all_jobs(
                            params.get('keywords')
                        )
                    else:
                        scraper_results = await self.scrapers[category].scrape(**params)
                    
                    results[category] = scraper_results
                    
                    # Save to database
                    self.save_to_database(category, scraper_results)
                    
                except Exception as e:
                    self.logger.error(f"Scraping {category} failed: {e}")
                    results[category] = {'error': str(e)}
        
        # Update scraping history
        self.update_scraping_history(results)
        
        return results
    
    def save_to_database(self, category: str, data: Any):
        """Save scraped data to database"""
        # Implementation would depend on your database setup
        timestamp = datetime.now().isoformat()
        
        # For now, save to JSON files
        filename = f"data/scraped/{category}_{timestamp.replace(':', '-')}.json"
        
        with open(filename, 'w') as f:
            if isinstance(data, list):
                json.dump(data, f, indent=2, default=str)
            else:
                json.dump(data, f, indent=2, default=str)
    
    def update_scraping_history(self, results: Dict[str, Any]):
        """Update scraping history"""
        history_entry = {
            'timestamp': datetime.now().isoformat(),
            'results_summary': {
                category: len(data) if isinstance(data, list) else 'multiple'
                for category, data in results.items()
            },
            'total_items': sum(
                len(data) if isinstance(data, list) else 0 
                for data in results.values()
            )
        }
        
        self.scraping_history.append(history_entry)
        
        # Keep only last 100 entries
        if len(self.scraping_history) > 100:
            self.scraping_history = self.scraping_history[-100:]
    
    async def schedule_scraping(self, interval_minutes: int = 60):
        """Schedule periodic scraping"""
        while True:
            try:
                await self.run_comprehensive_scrape()
                self.logger.info(f"Scraping completed. Next in {interval_minutes} minutes.")
                
                await asyncio.sleep(interval_minutes * 60)
                
            except Exception as e:
                self.logger.error(f"Scheduled scraping failed: {e}")
                await asyncio.sleep(300)  # Wait 5 minutes on error
    
    def get_scraping_stats(self) -> Dict[str, Any]:
        """Get scraping statistics"""
        if not self.scraping_history:
            return {}
        
        latest = self.scraping_history[-1]
        
        return {
            'last_scraping': latest['timestamp'],
            'total_categories': len(latest['results_summary']),
            'total_items': latest['total_items'],
            'history_entries': len(self.scraping_history),
            'categories': list(latest['results_summary'].keys())
        }

class ScrapingDashboard:
    def __init__(self, scraping_manager: ComprehensiveScrapingManager):
        self.manager = scraping_manager
        self.logger = logging.getLogger('ScrapingDashboard')
    
    async def get_dashboard_data(self) -> Dict[str, Any]:
        """Get data for scraping dashboard"""
        stats = self.manager.get_scraping_stats()
        
        # Get recent data samples
        recent_data = await self.get_recent_data_samples()
        
        return {
            'stats': stats,
            'recent_data': recent_data,
            'active_scrapers': list(self.manager.scrapers.keys()),
            'system_status': 'active'
        }
    
    async def get_recent_data_samples(self) -> Dict[str, Any]:
        """Get samples of recently scraped data"""
        samples = {}
        
        for category in self.manager.scrapers.keys():
            try:
                # Get most recent file for each category
                recent_file = self.find_most_recent_file(category)
                if recent_file:
                    with open(recent_file, 'r') as f:
                        data = json.load(f)
                    
                    # Take first 5 items as sample
                    if isinstance(data, list):
                        samples[category] = data[:5]
                    else:
                        samples[category] = [data]
            except Exception as e:
                self.logger.error(f"Error getting sample for {category}: {e}")
        
        return samples
    
    def find_most_recent_file(self, category: str) -> Optional[str]:
        """Find most recent file for a category"""
        import glob
        import os
        
        pattern = f"data/scraped/{category}_*.json"
        files = glob.glob(pattern)
        
        if not files:
            return None
        
        return max(files, key=os.path.getctime)
