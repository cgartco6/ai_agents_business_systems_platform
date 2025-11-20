import re
from datetime import datetime, timedelta
from typing import List, Dict, Any
from .base_scraper import BaseScraper, ScrapingConfig

class LinkedInScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.base_url = "https://www.linkedin.com/jobs/search/"
    
    async def scrape(self, keywords: List[str] = None, location: str = "South Africa", 
                    max_pages: int = 5) -> List[Dict[str, Any]]:
        """Scrape LinkedIn jobs"""
        
        if keywords is None:
            keywords = ['python', 'ai', 'machine learning', 'data scientist', 'software engineer']
        
        all_jobs = []
        
        for keyword in keywords:
            self.logger.info(f"Scraping LinkedIn for: {keyword}")
            
            for page in range(max_pages):
                params = {
                    'keywords': keyword,
                    'location': location,
                    'start': page * 25
                }
                
                url = f"{self.base_url}?{'&'.join(f'{k}={v}' for k, v in params.items())}"
                html = await self.fetch_url(url)
                
                if html:
                    jobs = self.parse_linkedin_page(html, keyword)
                    all_jobs.extend(jobs)
                    
                    # Respect rate limiting
                    await asyncio.sleep(self.config.request_delay)
        
        return self.normalize_data(all_jobs)
    
    def parse_linkedin_page(self, html: str, keyword: str) -> List[Dict[str, Any]]:
        """Parse LinkedIn jobs page"""
        soup = BeautifulSoup(html, 'html.parser')
        jobs = []
        
        job_cards = soup.find_all('div', class_='base-card')  # LinkedIn job card class
        
        for card in job_cards:
            try:
                title_elem = card.find('h3', class_='base-search-card__title')
                company_elem = card.find('h4', class_='base-search-card__subtitle')
                location_elem = card.find('span', class_='job-search-card__location')
                link_elem = card.find('a', class_='base-card__full-link')
                
                if all([title_elem, company_elem, location_elem, link_elem]):
                    job = {
                        'title': title_elem.get_text().strip(),
                        'company': company_elem.get_text().strip(),
                        'location': location_elem.get_text().strip(),
                        'url': link_elem.get('href', '').split('?')[0],
                        'source': 'linkedin',
                        'keyword': keyword,
                        'scraped_at': datetime.now().isoformat(),
                        'salary': self.extract_salary(card),
                        'posted_date': self.extract_date(card)
                    }
                    jobs.append(job)
            except Exception as e:
                self.logger.error(f"Error parsing LinkedIn job card: {e}")
        
        return jobs
    
    def extract_salary(self, card) -> str:
        """Extract salary information if available"""
        salary_elem = card.find('span', class_='job-search-card__salary-info')
        return salary_elem.get_text().strip() if salary_elem else ''
    
    def extract_date(self, card) -> str:
        """Extract job posting date"""
        date_elem = card.find('time')
        if date_elem and date_elem.get('datetime'):
            return date_elem.get('datetime')
        return ''

class IndeedScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.base_url = "https://za.indeed.com"
    
    async def scrape(self, keywords: List[str] = None, location: str = "South Africa") -> List[Dict[str, Any]]:
        """Scrape Indeed jobs"""
        
        if keywords is None:
            keywords = ['python developer', 'data scientist', 'software engineer']
        
        all_jobs = []
        
        for keyword in keywords:
            self.logger.info(f"Scraping Indeed for: {keyword}")
            
            params = {
                'q': keyword,
                'l': location
            }
            
            url = f"{self.base_url}/jobs?{'&'.join(f'{k}={v}' for k, v in params.items())}"
            html = await self.fetch_url(url)
            
            if html:
                jobs = self.parse_indeed_page(html, keyword)
                all_jobs.extend(jobs)
        
        return self.normalize_data(all_jobs)
    
    def parse_indeed_page(self, html: str, keyword: str) -> List[Dict[str, Any]]:
        """Parse Indeed jobs page"""
        soup = BeautifulSoup(html, 'html.parser')
        jobs = []
        
        job_cards = soup.find_all('div', class_='job_seen_beacon')
        
        for card in job_cards:
            try:
                title_elem = card.find('h2', class_='jobTitle')
                company_elem = card.find('span', class_='companyName')
                location_elem = card.find('div', class_='companyLocation')
                link_elem = card.find('a', class_='jcs-JobTitle')
                
                if all([title_elem, company_elem, location_elem, link_elem]):
                    job = {
                        'title': title_elem.get_text().strip(),
                        'company': company_elem.get_text().strip(),
                        'location': location_elem.get_text().strip(),
                        'url': urljoin(self.base_url, link_elem.get('href', '')),
                        'source': 'indeed',
                        'keyword': keyword,
                        'scraped_at': datetime.now().isoformat(),
                        'salary': self.extract_indeed_salary(card),
                        'summary': self.extract_summary(card)
                    }
                    jobs.append(job)
            except Exception as e:
                self.logger.error(f"Error parsing Indeed job card: {e}")
        
        return jobs
    
    def extract_indeed_salary(self, card) -> str:
        """Extract salary from Indeed job card"""
        salary_elem = card.find('div', class_='salary-snippet-container')
        return salary_elem.get_text().strip() if salary_elem else ''
    
    def extract_summary(self, card) -> str:
        """Extract job summary"""
        summary_elem = card.find('div', class_='job-snippet')
        return summary_elem.get_text().strip() if summary_elem else ''

class CareerJunctionScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.base_url = "https://www.careerjunction.co.za"
    
    async def scrape(self, keywords: List[str] = None) -> List[Dict[str, Any]]:
        """Scrape CareerJunction jobs (South Africa specific)"""
        
        if keywords is None:
            keywords = ['python', 'developer', 'data', 'software']
        
        all_jobs = []
        
        for keyword in keywords:
            self.logger.info(f"Scraping CareerJunction for: {keyword}")
            
            url = f"{self.base_url}/jobs/results?keywords={keyword}"
            html = await self.fetch_url(url)
            
            if html:
                jobs = self.parse_careerjunction_page(html, keyword)
                all_jobs.extend(jobs)
        
        return self.normalize_data(all_jobs)
    
    def parse_careerjunction_page(self, html: str, keyword: str) -> List[Dict[str, Any]]:
        """Parse CareerJunction jobs page"""
        soup = BeautifulSoup(html, 'html.parser')
        jobs = []
        
        job_cards = soup.find_all('div', class_='job-result')  # Adjust based on actual class
        
        for card in job_cards:
            try:
                title_elem = card.find('h2')  # Adjust selector
                company_elem = card.find('span', class_='company')  # Adjust selector
                location_elem = card.find('span', class_='location')  # Adjust selector
                link_elem = card.find('a', href=True)
                
                if all([title_elem, company_elem, location_elem, link_elem]):
                    job = {
                        'title': title_elem.get_text().strip(),
                        'company': company_elem.get_text().strip(),
                        'location': location_elem.get_text().strip(),
                        'url': urljoin(self.base_url, link_elem.get('href', '')),
                        'source': 'careerjunction',
                        'keyword': keyword,
                        'scraped_at': datetime.now().isoformat(),
                        'category': self.extract_category(card)
                    }
                    jobs.append(job)
            except Exception as e:
                self.logger.error(f"Error parsing CareerJunction job card: {e}")
        
        return jobs
    
    def extract_category(self, card) -> str:
        """Extract job category"""
        category_elem = card.find('span', class_='category')  # Adjust selector
        return category_elem.get_text().strip() if category_elem else ''

class JobScrapingManager:
    def __init__(self, config: ScrapingConfig):
        self.config = config
        self.scrapers = {
            'linkedin': LinkedInScraper(config),
            'indeed': IndeedScraper(config),
            'careerjunction': CareerJunctionScraper(config)
        }
        self.orchestrator = ScrapingOrchestrator()
        
        for name, scraper in self.scrapers.items():
            self.orchestrator.register_scraper(name, scraper)
    
    async def scrape_all_jobs(self, keywords: List[str] = None) -> Dict[str, Any]:
        """Scrape jobs from all platforms"""
        return await self.orchestrator.run_scrapers()
    
    async def search_jobs(self, query: str, location: str = "South Africa") -> List[Dict[str, Any]]:
        """Search jobs across all platforms"""
        keywords = [query] + query.split()  # Search for full phrase and individual words
        
        all_results = await self.scrape_all_jobs(keywords)
        
        # Consolidate and rank results
        consolidated = []
        for platform, results in all_results.items():
            if results['data']:
                consolidated.extend(results['data'])
        
        # Remove duplicates and rank by relevance
        return self.rank_jobs(consolidated, query)
    
    def rank_jobs(self, jobs: List[Dict[str, Any]], query: str) -> List[Dict[str, Any]]:
        """Rank jobs by relevance to query"""
        scored_jobs = []
        
        for job in jobs:
            score = 0
            
            # Title match (highest weight)
            if query.lower() in job['title'].lower():
                score += 10
            
            # Keyword matches
            for word in query.lower().split():
                if word in job['title'].lower():
                    score += 3
                if word in job.get('summary', '').lower():
                    score += 1
            
            # Recency bonus
            if 'posted_date' in job:
                try:
                    posted_date = datetime.fromisoformat(job['posted_date'].replace('Z', '+00:00'))
                    days_ago = (datetime.now().replace(tzinfo=posted_date.tzinfo) - posted_date).days
                    if days_ago <= 1:
                        score += 5
                    elif days_ago <= 7:
                        score += 2
                except:
                    pass
            
            job['relevance_score'] = score
            scored_jobs.append(job)
        
        # Sort by score descending
        return sorted(scored_jobs, key=lambda x: x['relevance_score'], reverse=True)
