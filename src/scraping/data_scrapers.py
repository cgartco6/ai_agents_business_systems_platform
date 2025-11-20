import pandas as pd
import csv
from typing import List, Dict, Any
import sqlite3
from .base_scraper import BaseScraper, ScrapingConfig

class FinancialDataScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.market_sources = {
            'jse': 'https://www.sharenet.co.za/v3/quotes.php',
            'crypto': 'https://api.coingecko.com/api/v3',
            'forex': 'https://api.exchangerate-api.com/v4/latest/ZAR'
        }
    
    async def scrape(self, data_types: List[str] = None) -> List[Dict[str, Any]]:
        """Scrape financial data"""
        
        if data_types is None:
            data_types = ['jse', 'crypto', 'forex']
        
        all_data = []
        
        for data_type in data_types:
            if data_type == 'jse':
                jse_data = await self.scrape_jse_data()
                all_data.extend(jse_data)
            elif data_type == 'crypto':
                crypto_data = await self.scrape_crypto_data()
                all_data.extend(crypto_data)
            elif data_type == 'forex':
                forex_data = await self.scrape_forex_data()
                all_data.extend(forex_data)
        
        return all_data
    
    async def scrape_jse_data(self) -> List[Dict[str, Any]]:
        """Scrape JSE stock data"""
        # This would need to be adapted based on the actual JSE data source
        url = self.market_sources['jse']
        html = await self.fetch_url(url)
        
        if html:
            return self.parse_jse_html(html)
        return []
    
    def parse_jse_html(self, html: str) -> List[Dict[str, Any]]:
        """Parse JSE stock data from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        stocks = []
        
        # This is a simplified parser - would need adjustment for actual site structure
        stock_rows = soup.find_all('tr', class_='stock-row')  # Adjust selector
        
        for row in stock_rows:
            try:
                cells = row.find_all('td')
                if len(cells) >= 5:
                    stock = {
                        'symbol': cells[0].get_text().strip(),
                        'name': cells[1].get_text().strip(),
                        'price': float(cells[2].get_text().strip().replace(',', '')),
                        'change': cells[3].get_text().strip(),
                        'volume': int(cells[4].get_text().strip().replace(',', '')),
                        'source': 'jse',
                        'scraped_at': datetime.now().isoformat()
                    }
                    stocks.append(stock)
            except Exception as e:
                self.logger.error(f"Error parsing JSE stock row: {e}")
        
        return stocks
    
    async def scrape_crypto_data(self) -> List[Dict[str, Any]]:
        """Scrape cryptocurrency data from CoinGecko"""
        url = f"{self.market_sources['crypto']}/coins/markets"
        params = {
            'vs_currency': 'usd',
            'order': 'market_cap_desc',
            'per_page': 100,
            'page': 1,
            'sparkline': 'false'
        }
        
        async with self.session.get(url, params=params) as response:
            if response.status == 200:
                data = await response.json()
                return self.parse_crypto_json(data)
        
        return []
    
    def parse_crypto_json(self, data: List[Dict]) -> List[Dict[str, Any]]:
        """Parse cryptocurrency JSON data"""
        crypto_data = []
        
        for coin in data:
            crypto = {
                'symbol': coin['symbol'].upper(),
                'name': coin['name'],
                'current_price': coin['current_price'],
                'market_cap': coin['market_cap'],
                'market_cap_rank': coin['market_cap_rank'],
                'price_change_24h': coin['price_change_24h'],
                'price_change_percentage_24h': coin['price_change_percentage_24h'],
                'source': 'coingecko',
                'scraped_at': datetime.now().isoformat()
            }
            crypto_data.append(crypto)
        
        return crypto_data
    
    async def scrape_forex_data(self) -> List[Dict[str, Any]]:
        """Scrape forex data"""
        url = self.market_sources['forex']
        
        async with self.session.get(url) as response:
            if response.status == 200:
                data = await response.json()
                return self.parse_forex_json(data)
        
        return []
    
    def parse_forex_json(self, data: Dict) -> List[Dict[str, Any]]:
        """Parse forex JSON data"""
        forex_data = []
        base_currency = data['base']
        rates = data['rates']
        
        for currency, rate in rates.items():
            if currency != base_currency:
                forex = {
                    'base_currency': base_currency,
                    'target_currency': currency,
                    'exchange_rate': rate,
                    'source': 'exchangerate-api',
                    'scraped_at': datetime.now().isoformat()
                }
                forex_data.append(forex)
        
        return forex_data

class RealEstateScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.sources = {
            'property24': 'https://www.property24.co.za',
            'privateproperty': 'https://www.privateproperty.co.za'
        }
    
    async def scrape(self, property_type: str = "house", location: str = "johannesburg") -> List[Dict[str, Any]]:
        """Scrape real estate listings"""
        all_listings = []
        
        for source_name, base_url in self.sources.items():
            self.logger.info(f"Scraping {source_name} for {property_type} in {location}")
            
            if source_name == 'property24':
                listings = await self.scrape_property24(property_type, location, base_url)
            elif source_name == 'privateproperty':
                listings = await self.scrape_private_property(property_type, location, base_url)
            
            all_listings.extend(listings)
        
        return self.normalize_data(all_listings)
    
    async def scrape_property24(self, property_type: str, location: str, base_url: str) -> List[Dict[str, Any]]:
        """Scrape Property24 listings"""
        url = f"{base_url}/for-sale/{location}/{property_type}"
        html = await self.fetch_url(url)
        
        if html:
            return self.parse_property24_html(html, base_url)
        return []
    
    def parse_property24_html(self, html: str, base_url: str) -> List[Dict[str, Any]]:
        """Parse Property24 listings"""
        soup = BeautifulSoup(html, 'html.parser')
        listings = []
        
        listing_cards = soup.find_all('div', class_='p24_listingCard')  # Adjust selector
        
        for card in listing_cards:
            try:
                title_elem = card.find('h3')  # Adjust selector
                price_elem = card.find('div', class_='p24_price')  # Adjust selector
                location_elem = card.find('div', class_='p24_location')  # Adjust selector
                link_elem = card.find('a', href=True)
                
                if all([title_elem, price_elem, location_elem, link_elem]):
                    listing = {
                        'title': title_elem.get_text().strip(),
                        'price': self.clean_price(price_elem.get_text().strip()),
                        'location': location_elem.get_text().strip(),
                        'url': urljoin(base_url, link_elem.get('href', '')),
                        'source': 'property24',
                        'scraped_at': datetime.now().isoformat(),
                        'bedrooms': self.extract_bedrooms(card),
                        'bathrooms': self.extract_bathrooms(card)
                    }
                    listings.append(listing)
            except Exception as e:
                self.logger.error(f"Error parsing Property24 listing: {e}")
        
        return listings
    
    def clean_price(self, price_text: str) -> str:
        """Clean and normalize price text"""
        # Remove extra spaces and normalize
        return ' '.join(price_text.split())
    
    def extract_bedrooms(self, card) -> int:
        """Extract number of bedrooms"""
        # Implementation depends on site structure
        return 0
    
    def extract_bathrooms(self, card) -> int:
        """Extract number of bathrooms"""
        # Implementation depends on site structure
        return 0

class WebDataScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
    
    async def scrape_website_data(self, url: str, selectors: Dict[str, str]) -> Dict[str, Any]:
        """Scrape structured data from any website using CSS selectors"""
        html = await self.fetch_url(url)
        
        if not html:
            return {}
        
        soup = BeautifulSoup(html, 'html.parser')
        data = {}
        
        for key, selector in selectors.items():
            try:
                elements = soup.select(selector)
                if elements:
                    if len(elements) == 1:
                        data[key] = elements[0].get_text().strip()
                    else:
                        data[key] = [elem.get_text().strip() for elem in elements]
                else:
                    data[key] = None
            except Exception as e:
                self.logger.error(f"Error extracting {key} with selector {selector}: {e}")
                data[key] = None
        
        data['source_url'] = url
        data['scraped_at'] = datetime.now().isoformat()
        
        return data
    
    async def scrape_multiple_pages(self, urls: List[str], selectors: Dict[str, str]) -> List[Dict[str, Any]]:
        """Scrape multiple pages concurrently"""
        tasks = [self.scrape_website_data(url, selectors) for url in urls]
        results = await asyncio.gather(*tasks)
        return [result for result in results if result]
