from flask import Blueprint, request, jsonify
from src.scraping.scraping_manager import ComprehensiveScrapingManager
import asyncio

scraping_bp = Blueprint('scraping', __name__)
scraping_manager = ComprehensiveScrapingManager()

@scraping_bp.route('/api/scraping/run', methods=['POST'])
async def run_scraping():
    """Run comprehensive scraping"""
    try:
        data = request.json or {}
        targets = data.get('targets', {})
        
        results = await scraping_manager.run_comprehensive_scrape(targets)
        
        return jsonify({
            'status': 'success',
            'results': results,
            'message': 'Scraping completed successfully'
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Scraping failed: {str(e)}'
        }), 500

@scraping_bp.route('/api/scraping/jobs/search', methods=['POST'])
async def search_jobs():
    """Search jobs across all platforms"""
    try:
        data = request.json or {}
        query = data.get('query', '')
        location = data.get('location', 'South Africa')
        
        job_manager = scraping_manager.scrapers['jobs']
        results = await job_manager.search_jobs(query, location)
        
        return jsonify({
            'status': 'success',
            'query': query,
            'location': location,
            'results': results,
            'total_count': len(results)
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Job search failed: {str(e)}'
        }), 500

@scraping_bp.route('/api/scraping/financial/markets', methods=['GET'])
async def get_financial_data():
    """Get financial market data"""
    try:
        financial_scraper = scraping_manager.scrapers['financial']
        data = await financial_scraper.scrape()
        
        return jsonify({
            'status': 'success',
            'data': data,
            'total_items': len(data)
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Financial data scraping failed: {str(e)}'
        }), 500

@scraping_bp.route('/api/scraping/odds/sports', methods=['GET'])
async def get_sports_odds():
    """Get sports betting odds"""
    try:
        sports = request.args.getlist('sports') or ['soccer', 'rugby']
        
        odds_scraper = scraping_manager.scrapers['odds']
        data = await odds_scraper.scrape(sports)
        
        return jsonify({
            'status': 'success',
            'sports': sports,
            'data': data,
            'total_matches': len(data)
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Odds scraping failed: {str(e)}'
        }), 500

@scraping_bp.route('/api/scraping/stats', methods=['GET'])
async def get_scraping_stats():
    """Get scraping statistics"""
    try:
        stats = scraping_manager.get_scraping_stats()
        
        return jsonify({
            'status': 'success',
            'stats': stats
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Stats retrieval failed: {str(e)}'
        }), 500

@scraping_bp.route('/api/scraping/website', methods=['POST'])
async def scrape_website():
    """Scrape data from specific website"""
    try:
        data = request.json
        url = data.get('url')
        selectors = data.get('selectors', {})
        
        if not url:
            return jsonify({'status': 'error', 'message': 'URL is required'}), 400
        
        web_scraper = scraping_manager.scrapers['web']
        result = await web_scraper.scrape_website_data(url, selectors)
        
        return jsonify({
            'status': 'success',
            'url': url,
            'data': result
        })
    
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Website scraping failed: {str(e)}'
        }), 500
