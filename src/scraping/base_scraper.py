import asyncio
import aiohttp
from bs4 import BeautifulSoup
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from typing import List, Dict, Any, Optional
import json
import time
import random
from urllib.parse import urljoin, urlparse
import logging
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class ScrapingConfig:
    max_concurrent: int = 5
    request_delay: float = 1.0
    timeout: int = 30
    retry_attempts: int = 3
    respect_robots_txt: bool = True
    user_agents: List[str] = None

class BaseScraper(ABC):
    def __init__(self, config: ScrapingConfig):
        self.config = config
        self.session = None
        self.driver = None
        self.logger = logging.getLogger(self.__class__.__name__)
        
        if not self.config.user_agents:
            self.config.user_agents = [
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            ]
    
    async def initialize(self):
        """Initialize async session"""
        self.session = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=self.config.timeout),
            headers={'User-Agent': random.choice(self.config.user_agents)}
        )
    
    async def close(self):
        """Cleanup resources"""
        if self.session:
            await self.session.close()
        if self.driver:
            self.driver.quit()
    
    def get_random_headers(self) -> Dict[str, str]:
        """Get random headers to avoid detection"""
        return {
            'User-Agent': random.choice(self.config.user_agents),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
    
    async def fetch_url(self, url: str, method: str = 'GET', **kwargs) -> Optional[str]:
        """Fetch URL with retry logic"""
        for attempt in range(self.config.retry_attempts):
            try:
                headers = self.get_random_headers()
                async with self.session.request(method, url, headers=headers, **kwargs) as response:
                    if response.status == 200:
                        return await response.text()
                    elif response.status == 429:  # Rate limited
                        wait_time = (2 ** attempt) + random.random()
                        self.logger.warning(f"Rate limited, waiting {wait_time}s")
                        await asyncio.sleep(wait_time)
                    else:
                        self.logger.error(f"HTTP {response.status} for {url}")
            except Exception as e:
                self.logger.error(f"Attempt {attempt + 1} failed for {url}: {e}")
                if attempt == self.config.retry_attempts - 1:
                    return None
                await asyncio.sleep((2 ** attempt) + random.random())
        
        return None
    
    def initialize_selenium(self):
        """Initialize Selenium WebDriver for JS-heavy sites"""
        options = webdriver.ChromeOptions()
        options.add_argument('--headless')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        options.add_argument(f'--user-agent={random.choice(self.config.user_agents)}')
        
        self.driver = webdriver.Chrome(options=options)
        return self.driver
    
    def selenium_fetch(self, url: str, wait_for: str = None, timeout: int = 10) -> Optional[str]:
        """Fetch URL using Selenium for JavaScript-rendered content"""
        try:
            self.driver.get(url)
            
            if wait_for:
                WebDriverWait(self.driver, timeout).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, wait_for))
                )
            
            return self.driver.page_source
        except Exception as e:
            self.logger.error(f"Selenium fetch failed for {url}: {e}")
            return None
    
    @abstractmethod
    async def scrape(self, *args, **kwargs) -> List[Dict[str, Any]]:
        """Main scraping method to be implemented by subclasses"""
        pass
    
    def save_data(self, data: List[Dict[str, Any]], filename: str):
        """Save scraped data to JSON file"""
        with open(f'data/scraped/{filename}_{int(time.time())}.json', 'w') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def normalize_data(self, data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Normalize and clean scraped data"""
        normalized = []
        for item in data:
            # Remove empty values
            cleaned = {k: v for k, v in item.items() if v not in [None, '', []]}
            
            # Convert all values to string and strip whitespace
            for key, value in cleaned.items():
                if isinstance(value, str):
                    cleaned[key] = value.strip()
                elif isinstance(value, (list, dict)):
                    cleaned[key] = json.dumps(value)
            
            normalized.append(cleaned)
        
        return normalized

class ScrapingOrchestrator:
    def __init__(self):
        self.scrapers = {}
        self.active_tasks = []
        
    def register_scraper(self, name: str, scraper: BaseScraper):
        """Register a scraper"""
        self.scrapers[name] = scraper
    
    async def run_scrapers(self, scraper_names: List[str] = None) -> Dict[str, Any]:
        """Run multiple scrapers concurrently"""
        if scraper_names is None:
            scraper_names = list(self.scrapers.keys())
        
        tasks = []
        for name in scraper_names:
            if name in self.scrapers:
                tasks.append(self._run_single_scraper(name, self.scrapers[name]))
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        consolidated = {}
        for name, result in zip(scraper_names, results):
            if isinstance(result, Exception):
                consolidated[name] = {'error': str(result), 'data': []}
            else:
                consolidated[name] = {'data': result, 'error': None}
        
        return consolidated
    
    async def _run_single_scraper(self, name: str, scraper: BaseScraper):
        """Run a single scraper"""
        try:
            await scraper.initialize()
            data = await scraper.scrape()
            scraper.save_data(data, name)
            return data
        except Exception as e:
            logging.error(f"Scraper {name} failed: {e}")
            return []
        finally:
            await scraper.close()
