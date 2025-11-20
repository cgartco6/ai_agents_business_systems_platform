import re
from datetime import datetime
from typing import List, Dict, Any
from .base_scraper import BaseScraper, ScrapingConfig

class BettingOddsScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.sportsbooks = {
            'betway': 'https://www.betway.co.za/sports',
            'sportingbet': 'https://www.sportingbet.co.za/sports',
            'hollywoodbets': 'https://www.hollywoodbets.net'
        }
    
    async def scrape(self, sports: List[str] = None) -> List[Dict[str, Any]]:
        """Scrape betting odds for various sports"""
        
        if sports is None:
            sports = ['soccer', 'rugby', 'cricket', 'tennis', 'basketball']
        
        all_odds = []
        
        for sport in sports:
            for bookmaker, base_url in self.sportsbooks.items():
                self.logger.info(f"Scraping {bookmaker} for {sport} odds")
                
                odds = await self.scrape_sport_odds(bookmaker, sport, base_url)
                all_odds.extend(odds)
                
                await asyncio.sleep(self.config.request_delay)
        
        return self.normalize_data(all_odds)
    
    async def scrape_sport_odds(self, bookmaker: str, sport: str, base_url: str) -> List[Dict[str, Any]]:
        """Scrape odds for a specific sport from a bookmaker"""
        
        # This would need to be adapted for each bookmaker's URL structure
        if bookmaker == 'betway':
            url = f"{base_url}/{sport}"
        elif bookmaker == 'sportingbet':
            url = f"{base_url}/{sport}"
        else:
            url = base_url  # Generic approach
        
        html = await self.fetch_url(url)
        
        if html:
            return self.parse_odds_html(html, bookmaker, sport)
        return []
    
    def parse_odds_html(self, html: str, bookmaker: str, sport: str) -> List[Dict[str, Any]]:
        """Parse betting odds from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        matches = []
        
        # This is a generic parser - each bookmaker would need specific selectors
        match_cards = soup.find_all('div', class_=re.compile(r'match|event', re.I))
        
        for card in match_cards:
            try:
                teams = card.find_all('span', class_=re.compile(r'team|participant', re.I))
                odds_elements = card.find_all('span', class_=re.compile(r'odds|price', re.I))
                
                if len(teams) >= 2 and len(odds_elements) >= 2:
                    match = {
                        'sport': sport,
                        'bookmaker': bookmaker,
                        'team1': teams[0].get_text().strip(),
                        'team2': teams[1].get_text().strip(),
                        'odds1': self.parse_odds_value(odds_elements[0].get_text()),
                        'odds2': self.parse_odds_value(odds_elements[1].get_text()),
                        'draw_odds': self.parse_odds_value(odds_elements[2].get_text()) if len(odds_elements) > 2 else None,
                        'match_time': self.extract_match_time(card),
                        'scraped_at': datetime.now().isoformat()
                    }
                    matches.append(match)
            except Exception as e:
                self.logger.error(f"Error parsing {bookmaker} odds: {e}")
        
        return matches
    
    def parse_odds_value(self, odds_text: str) -> float:
        """Parse odds text into float value"""
        try:
            # Handle different odds formats: 2.5, 5/2, +150, etc.
            if '/' in odds_text:
                numerator, denominator = odds_text.split('/')
                return float(numerator) / float(denominator) + 1
            elif odds_text.startswith('+'):
                return (float(odds_text[1:]) / 100) + 1
            else:
                return float(odds_text)
        except:
            return 0.0
    
    def extract_match_time(self, card) -> str:
        """Extract match date and time"""
        time_elem = card.find('span', class_=re.compile(r'time|date', re.I))
        return time_elem.get_text().strip() if time_elem else ''

class TeamDataScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.sports_sources = {
            'soccer': {
                'premier_league': 'https://www.premierleague.com',
                'la_liga': 'https://www.laliga.com',
                'bundesliga': 'https://www.bundesliga.com'
            },
            'rugby': {
                'super_rugby': 'https://www.sanzarrugby.com',
                'premiership': 'https://www.premiershiprugby.com'
            },
            'cricket': {
                'icc': 'https://www.icc-cricket.com',
                'csa': 'https://cricket.co.za'
            }
        }
    
    async def scrape(self, sports: List[str] = None) -> List[Dict[str, Any]]:
        """Scrape team data for various sports"""
        
        if sports is None:
            sports = ['soccer', 'rugby', 'cricket']
        
        all_teams = []
        
        for sport in sports:
            if sport in self.sports_sources:
                for league, base_url in self.sports_sources[sport].items():
                    self.logger.info(f"Scraping {league} teams")
                    
                    teams = await self.scrape_league_teams(sport, league, base_url)
                    all_teams.extend(teams)
        
        return self.normalize_data(all_teams)
    
    async def scrape_league_teams(self, sport: str, league: str, base_url: str) -> List[Dict[str, Any]]:
        """Scrape teams for a specific league"""
        # League-specific team pages would vary greatly
        teams_url = f"{base_url}/teams"  # This is a generic approach
        
        html = await self.fetch_url(teams_url)
        
        if html:
            return self.parse_teams_html(html, sport, league)
        return []
    
    def parse_teams_html(self, html: str, sport: str, league: str) -> List[Dict[str, Any]]:
        """Parse team data from HTML"""
        soup = BeautifulSoup(html, 'html.parser')
        teams = []
        
        team_cards = soup.find_all('div', class_=re.compile(r'team|club', re.I))
        
        for card in team_cards:
            try:
                name_elem = card.find('h3') or card.find('span', class_=re.compile(r'name', re.I))
                logo_elem = card.find('img')
                stats_elem = card.find('div', class_=re.compile(r'stats|record', re.I))
                
                if name_elem:
                    team = {
                        'sport': sport,
                        'league': league,
                        'name': name_elem.get_text().strip(),
                        'logo_url': logo_elem.get('src', '') if logo_elem else '',
                        'stats': stats_elem.get_text().strip() if stats_elem else '',
                        'scraped_at': datetime.now().isoformat()
                    }
                    teams.append(team)
            except Exception as e:
                self.logger.error(f"Error parsing team data: {e}")
        
        return teams

class APIScraper(BaseScraper):
    def __init__(self, config: ScrapingConfig):
        super().__init__(config)
        self.api_endpoints = {
            'football_data': 'https://api.football-data.org/v4',
            'cricket_data': 'https://api.cricapi.com/v1',
            'weather': 'https://api.openweathermap.org/data/2.5',
            'financial': 'https://www.alphavantage.co/query'
        }
    
    async def scrape(self, api_type: str, **params) -> List[Dict[str, Any]]:
        """Scrape data from various APIs"""
        
        if api_type == 'football':
            return await self.scrape_football_data(**params)
        elif api_type == 'cricket':
            return await self.scrape_cricket_data(**params)
        elif api_type == 'weather':
            return await self.scrape_weather_data(**params)
        elif api_type == 'stocks':
            return await self.scrape_stock_data(**params)
        else:
            self.logger.error(f"Unknown API type: {api_type}")
            return []
    
    async def scrape_football_data(self, league: str = 'PL') -> List[Dict[str, Any]]:
        """Scrape football data from API"""
        headers = {
            'X-Auth-Token': 'your-football-data-api-key'  # Would need actual API key
        }
        
        url = f"{self.api_endpoints['football_data']}/competitions/{league}/matches"
        
        async with self.session.get(url, headers=headers) as response:
            if response.status == 200:
                data = await response.json()
                return self.parse_football_matches(data)
        
        return []
    
    def parse_football_matches(self, data: Dict) -> List[Dict[str, Any]]:
        """Parse football matches from API response"""
        matches = []
        
        for match in data.get('matches', []):
            match_data = {
                'home_team': match['homeTeam']['name'],
                'away_team': match['awayTeam']['name'],
                'score': f"{match['score']['fullTime']['home']}-{match['score']['fullTime']['away']}",
                'status': match['status'],
                'match_date': match['utcDate'],
                'competition': match['competition']['name'],
                'source': 'football-data-api',
                'scraped_at': datetime.now().isoformat()
            }
            matches.append(match_data)
        
        return matches
    
    async def scrape_weather_data(self, cities: List[str] = None) -> List[Dict[str, Any]]:
        """Scrape weather data for cities"""
        if cities is None:
            cities = ['Johannesburg', 'Cape Town', 'Durban', 'Pretoria']
        
        weather_data = []
        api_key = 'your-openweather-api-key'  # Would need actual API key
        
        for city in cities:
            url = f"{self.api_endpoints['weather']}/weather"
            params = {
                'q': city,
                'appid': api_key,
                'units': 'metric'
            }
            
            async with self.session.get(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    weather = {
                        'city': city,
                        'temperature': data['main']['temp'],
                        'humidity': data['main']['humidity'],
                        'description': data['weather'][0]['description'],
                        'wind_speed': data['wind']['speed'],
                        'source': 'openweathermap',
                        'scraped_at': datetime.now().isoformat()
                    }
                    weather_data.append(weather)
            
            await asyncio.sleep(0.5)  # Rate limiting
        
        return weather_data
