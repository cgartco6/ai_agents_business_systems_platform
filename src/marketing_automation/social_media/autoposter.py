from typing import List, Dict, Any
import asyncio
from .platform_adapters import TikTok, Instagram, YouTube, Facebook, TwitterX

class SocialMediaAutoposter:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.platforms = {
            'tiktok': TikTok(config['tiktok']),
            'instagram': Instagram(config['instagram']),
            'youtube': YouTube(config['youtube']),
            'facebook': Facebook(config['facebook']),
            'twitter': TwitterX(config['twitter']),
            'linkedin': LinkedIn(config['linkedin'])
        }
        
    async def cross_platform_post(self, 
                                content: Dict[str, Any],
                                platforms: List[str] = None) -> Dict[str, Any]:
        """Post content to all specified platforms"""
        
        if platforms is None:
            platforms = list(self.platforms.keys())
            
        results = {}
        tasks = []
        
        for platform_name in platforms:
            platform = self.platforms[platform_name]
            task = asyncio.create_task(
                self._post_to_platform(platform, content)
            )
            tasks.append((platform_name, task))
            
        for platform_name, task in tasks:
            try:
                results[platform_name] = await task
            except Exception as e:
                results[platform_name] = {'success': False, 'error': str(e)}
                
        return results
    
    async def _post_to_platform(self, platform, content: Dict[str, Any]) -> Dict[str, Any]:
        """Post content to a specific platform"""
        # Platform-specific posting logic
        return await platform.post_content(content)
