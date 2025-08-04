import 'dart:convert';

/// Comprehensive Knowledge Base for AI Companion
/// Contains detailed information about all app features, mechanics, and systems
class AIKnowledgeBase {
  static const String version = '2.0.0';
  static const String lastUpdated = '2024-12-19';

  /// Complete feature documentation organized by category
  static const Map<String, dynamic> knowledgeBase = {
    
    // =============================================================================
    // CORE GAMEPLAY FEATURES
    // =============================================================================
    
    "character_system": {
      "name": "Character System",
      "description": "Your digital avatar that grows stronger through real-world activities",
      "simple_explanation": "Think of your character as a virtual version of yourself that gets stronger when you exercise, explore, and complete quests in real life! 💪",
      "features": {
        "character_creation": {
          "name": "Character Creation",
          "explanation": "Create your unique hero! Choose your appearance, name, and starting class. Your character reflects your real-world journey.",
          "steps": [
            "Tap 'Create Character' on the main screen",
            "Choose your character's appearance and style",
            "Select a starting class (Warrior, Mage, Ranger, or Scout)",
            "Pick a unique name for your hero",
            "Complete the tutorial to learn the basics!"
          ],
          "tips": [
            "Your starting class affects your initial abilities but you can learn all skills over time",
            "Character appearance can be changed later with cosmetic items",
            "Choose a name you love - it represents you in the game world!"
          ]
        },
        "leveling_system": {
          "name": "Character Leveling",
          "explanation": "Your character levels up by gaining Experience Points (XP) from real-world activities and in-game achievements!",
          "xp_sources": [
            "Walking/Running (1 XP per 100 steps)",
            "Completing quests (50-500 XP)",
            "Winning battles (25-100 XP)",
            "Discovering new locations (20-200 XP)",
            "Unlocking achievements (10-1000 XP)"
          ],
          "benefits": [
            "Higher stats (health, attack, defense)",
            "Access to new abilities and skills",
            "Unlock advanced equipment",
            "Participate in higher-level content"
          ]
        },
        "stats_system": {
          "name": "Character Stats",
          "explanation": "Your character has five main stats that determine their power and abilities",
          "stats": {
            "health": "How much damage you can take before being defeated",
            "attack": "How much damage you deal in combat",
            "defense": "How much damage you can block or resist",
            "speed": "How fast you move and act in battles",
            "energy": "Required to use special abilities and skills"
          },
          "improvement_methods": [
            "Level up your character",
            "Equip better cards and equipment",
            "Complete training quests",
            "Use stat-boosting items"
          ]
        }
      },
      "common_questions": {
        "How do I make my character stronger?": "Exercise in real life! Every step you take, every quest you complete, and every battle you win makes your character more powerful. It's like having a gym buddy who gets stronger when you do! 🏃‍♂️",
        "Can I change my character's appearance?": "Absolutely! Visit the Character Customization menu to change your look using cosmetic items you've earned or purchased.",
        "What happens when I level up?": "Level ups are exciting! You get stronger stats, unlock new abilities, and gain access to more challenging and rewarding content."
      }
    },

    "card_system": {
      "name": "Hybrid Card System",
      "description": "Revolutionary blend of physical and digital cards that power your abilities",
      "simple_explanation": "Imagine Pokemon cards that come to life in your phone! You can collect physical cards in real life and scan them to unlock digital versions with amazing powers! 🃏✨",
      "features": {
        "physical_cards": {
          "name": "Physical Card Collection",
          "explanation": "Real cards you can hold, trade, and collect! Each has a unique QR code that unlocks digital powers.",
          "how_to_get": [
            "Purchase starter decks and booster packs",
            "Trade with friends and other players",
            "Win them in tournaments and events",
            "Find them in special real-world locations",
            "Earn them through achievements"
          ],
          "scanning_process": [
            "Open the Card Scanner in the app",
            "Point your camera at the card's QR code",
            "Wait for the scan confirmation",
            "Watch your new card appear in your digital collection!",
            "Enjoy the awesome scan animation and effects!"
          ]
        },
        "digital_cards": {
          "name": "Digital Card Collection",
          "explanation": "Your phone-based card collection that powers your character's abilities in battles and quests.",
          "types": {
            "weapon_cards": "Swords, bows, staffs - equip these for combat power!",
            "armor_cards": "Shields, helmets, robes - protect yourself from damage!",
            "ability_cards": "Special moves and magic spells for battles!",
            "creature_cards": "Summon allies to fight alongside you!",
            "item_cards": "Potions, tools, and magical items for adventures!"
          },
          "rarity_system": {
            "common": "White border - Easy to find, good for beginners",
            "uncommon": "Green border - Decent power, moderately rare",
            "rare": "Blue border - Strong abilities, harder to find",
            "epic": "Purple border - Very powerful, quite rare",
            "legendary": "Gold border - Extremely powerful, very rare",
            "mythic": "Rainbow border - Godlike power, ultra rare!"
          }
        },
        "deck_building": {
          "name": "Deck Building",
          "explanation": "Create custom combinations of cards to match your playstyle and strategy!",
          "deck_rules": [
            "Each deck can have 20-30 cards",
            "Include a mix of weapons, armor, and abilities",
            "Consider your character's class and stats",
            "Balance offense and defense for best results"
          ],
          "deck_types": [
            "Aggressive Deck - Focus on quick, powerful attacks",
            "Defensive Deck - Emphasize protection and survival",
            "Balanced Deck - Mix of offense and defense",
            "Support Deck - Help teammates in group battles",
            "Specialist Deck - Focus on one specific strategy"
          ]
        }
      },
      "common_questions": {
        "How do I get my first cards?": "Great question! You'll get a free starter deck when you complete the tutorial. After that, you can earn card packs by completing quests, winning battles, or purchasing them in-game or in real life!",
        "What's the difference between physical and digital cards?": "Physical cards are real cards you can hold and trade with friends. When you scan them, they become digital cards in your app with special powers and abilities!",
        "How do I build a good deck?": "Start with the pre-made decks, then gradually replace cards as you find better ones. Think about what kind of player you are - do you like to attack fast, defend strongly, or use magic? Build your deck around your style!"
      }
    },

    "quest_system": {
      "name": "Adventure Quest System",
      "description": "Real-world adventures that blend physical exploration with digital rewards",
      "simple_explanation": "Turn your neighborhood into an adventure playground! Walk to real places, complete fun challenges, and earn amazing rewards! 🗺️⚔️",
      "features": {
        "quest_types": {
          "exploration_quests": {
            "name": "Exploration Quests",
            "explanation": "Visit real-world locations to discover hidden treasures and complete objectives!",
            "examples": [
              "Walk to the local park and 'defeat the guardian'",
              "Visit 5 different coffee shops to 'gather magical ingredients'",
              "Explore your downtown area to 'map the ancient kingdom'"
            ]
          },
          "fitness_quests": {
            "name": "Fitness Quests",
            "explanation": "Get healthy while having fun! These quests reward you for being active.",
            "examples": [
              "Walk 10,000 steps to 'complete the pilgrimage'",
              "Run 3 miles to 'escape the dragon's lair'",
              "Climb stairs to 'ascend the wizard's tower'"
            ]
          },
          "social_quests": {
            "name": "Social Quests",
            "explanation": "Team up with friends and guild members for group adventures!",
            "examples": [
              "Meet up with 3 friends at a location for a 'guild gathering'",
              "Complete a quest together with your guild",
              "Help a new player complete their first quest"
            ]
          },
          "puzzle_quests": {
            "name": "Puzzle Quests",
            "explanation": "Use your brain to solve riddles, codes, and mysteries!",
            "examples": [
              "Solve AR puzzles that appear in your camera",
              "Decode ancient messages to find treasure",
              "Answer trivia questions about your local area"
            ]
          }
        },
        "quest_rewards": {
          "experience_points": "Gain XP to level up your character",
          "card_packs": "Earn new cards to strengthen your deck",
          "in_game_currency": "Gold and gems to buy equipment and items",
          "achievements": "Unlock special titles and badges",
          "cosmetic_items": "New looks for your character and cards",
          "guild_reputation": "Improve your standing in your guild"
        },
        "difficulty_levels": {
          "beginner": "Easy quests perfect for new players - close to home, simple objectives",
          "intermediate": "Moderate challenges that require some planning and travel",
          "advanced": "Complex multi-part quests that may take days to complete",
          "expert": "Epic adventures for experienced players with amazing rewards",
          "legendary": "Ultra-rare world events that unite the entire community!"
        }
      },
      "common_questions": {
        "How do I find quests near me?": "Open the Quest Map and you'll see available quests in your area! The app uses your location to show nearby adventures. You can also filter by difficulty, type, and estimated time.",
        "What if I can't complete a quest?": "No worries! Most quests don't have time limits, so you can work on them at your own pace. If you're stuck, try asking your guild for help or check the quest hints in the app!",
        "Can I create my own quests?": "Not yet, but we're working on it! For now, you can suggest quest ideas through the feedback system, and we might add them to the game!"
      }
    },

    "battle_system": {
      "name": "Turn-Based Battle System",
      "description": "Strategic combat using your cards and character abilities",
      "simple_explanation": "Like chess meets Pokemon! Use your cards strategically to defeat opponents in fun, turn-based battles! 🛡️⚔️",
      "features": {
        "battle_types": {
          "pve_battles": {
            "name": "Player vs Environment",
            "explanation": "Fight against AI enemies and creatures during quests and exploration",
            "examples": ["Guardian battles at quest locations", "Random encounters while walking", "Boss fights in special areas"]
          },
          "pvp_battles": {
            "name": "Player vs Player",
            "explanation": "Challenge other real players to test your skills and strategy!",
            "formats": ["Casual matches", "Ranked battles", "Tournament matches", "Guild wars"]
          },
          "guild_raids": {
            "name": "Guild Raids",
            "explanation": "Team up with your guild to defeat massive bosses and earn epic rewards!",
            "mechanics": ["Coordinate with guild members", "Each player fights different parts of the boss", "Share rewards based on contribution"]
          }
        },
        "combat_mechanics": {
          "turn_structure": [
            "Each player draws a hand of 5 cards from their deck",
            "Players take turns playing cards and using abilities",
            "Cards require energy to play - manage it wisely!",
            "First player to reduce opponent's health to 0 wins!"
          ],
          "card_types_in_battle": {
            "attack_cards": "Deal damage to your opponent directly",
            "defense_cards": "Block incoming damage or heal yourself",
            "ability_cards": "Special effects like drawing cards or boosting stats",
            "creature_cards": "Summon allies that stay in battle to help you"
          },
          "strategy_tips": [
            "Balance aggressive attacks with defensive plays",
            "Save your most powerful cards for the right moment",
            "Watch your energy - don't use it all at once!",
            "Try to predict what your opponent might do next",
            "Use the environment and weather to your advantage"
          ]
        },
        "battle_rewards": {
          "winner_rewards": ["Experience points", "Card packs", "In-game currency", "Rating increases"],
          "participation_rewards": ["Small XP bonus", "Battle tokens", "Progress toward achievements"],
          "special_conditions": ["Perfect victory bonuses", "Comeback victory rewards", "First win of the day bonus"]
        }
      },
      "common_questions": {
        "How do I get better at battles?": "Practice makes perfect! Start with AI battles to learn the basics, experiment with different deck combinations, and watch how experienced players fight. Don't be afraid to lose - each battle teaches you something new!",
        "What happens if I lose a battle?": "Losing isn't the end! You still get participation rewards and valuable experience. Plus, you keep all your cards and can try again anytime!",
        "How does matchmaking work?": "The game matches you with players of similar skill level and card collection strength. As you get better, you'll face tougher opponents with better rewards!"
      }
    },

    "guild_system": {
      "name": "Guild & Social Features",
      "description": "Join communities of players for friendship, cooperation, and epic adventures",
      "simple_explanation": "Find your gaming family! Join a guild to make friends, help each other out, and tackle challenges that are too big for just one player! 👥🏰",
      "features": {
        "joining_guilds": {
          "explanation": "Guilds are groups of players who work together toward common goals",
          "how_to_join": [
            "Browse available guilds in the Guild Directory",
            "Look for guilds that match your playstyle and activity level",
            "Send a join request or accept an invitation",
            "Some guilds have requirements like minimum level or activity",
            "Once accepted, you're part of the guild family!"
          ],
          "guild_types": [
            "Casual - Relaxed, friendly environment for all players",
            "Competitive - Focused on tournaments and high-level play",
            "Social - Emphasis on chat, events, and community building",
            "Hardcore - Serious players who play frequently and intensively",
            "Regional - Players from the same geographic area"
          ]
        },
        "guild_benefits": {
          "social_features": [
            "Guild chat to talk with members anytime",
            "Coordinate real-world meetups and events",
            "Share screenshots and achievements",
            "Get help and advice from experienced players"
          ],
          "gameplay_benefits": [
            "Guild quests that require teamwork to complete",
            "Shared guild hall with collective upgrades",
            "Guild-only tournaments and competitions",
            "Bonus rewards for guild activities",
            "Access to guild bank for sharing resources"
          ],
          "progression_benefits": [
            "Guild levels that unlock new features",
            "Special guild achievements and titles",
            "Seasonal guild competitions with epic prizes",
            "Guild leaderboards to compete with other guilds"
          ]
        },
        "guild_roles": {
          "member": "Standard guild member with basic privileges",
          "officer": "Trusted member who can help manage the guild",
          "leader": "Guild founder or appointed leader with full control",
          "permissions": {
            "invite_players": "Officers and leaders can invite new members",
            "kick_players": "Officers and leaders can remove inactive members",
            "manage_events": "Plan and organize guild activities",
            "guild_bank": "Access to shared guild resources"
          }
        }
      },
      "common_questions": {
        "How do I find a good guild?": "Look for active guilds with friendly members who match your play schedule. Read their descriptions carefully and don't be afraid to try a few before finding your perfect fit!",
        "What if my guild isn't active anymore?": "You can leave and find a new guild anytime! There's no penalty for leaving, and there are always active guilds looking for new members.",
        "Can I create my own guild?": "Yes! Once you reach level 20, you can create your own guild. It costs some in-game currency, but then you're the leader and can build your own community!"
      }
    },

    "fitness_integration": {
      "name": "Fitness & Health Integration",
      "description": "Your real-world activity directly powers your in-game progress",
      "simple_explanation": "The more you move in real life, the stronger your character becomes! It's like having a personal trainer who gives you superpowers! 🏃‍♀️💪",
      "features": {
        "step_tracking": {
          "explanation": "Every step you take in real life gives your character experience points!",
          "conversion_rates": {
            "steps_to_xp": "1 XP for every 100 steps taken",
            "daily_bonuses": "Extra XP for reaching daily step goals",
            "streak_bonuses": "Bonus multipliers for consecutive active days",
            "challenge_bonuses": "Special rewards for fitness challenges"
          },
          "step_goals": [
            "Beginner: 5,000 steps per day",
            "Intermediate: 8,000 steps per day", 
            "Advanced: 10,000 steps per day",
            "Expert: 12,000+ steps per day"
          ]
        },
        "activity_tracking": {
          "supported_activities": [
            "Walking - Base XP for all movement",
            "Running - 2x XP multiplier for faster pace",
            "Cycling - Distance-based XP calculation",
            "Swimming - Special aquatic achievements",
            "Hiking - Exploration bonuses for elevation gain",
            "Sports - Team activity bonuses"
          ],
          "health_integration": {
            "google_fit": "Connects to Google Fit for Android users",
            "apple_health": "Integrates with Apple Health for iOS users",
            "fitness_trackers": "Works with Fitbit, Garmin, and other devices",
            "manual_entry": "Option to manually log activities"
          }
        },
        "fitness_rewards": {
          "immediate_rewards": [
            "Experience points for your character",
            "Energy restoration for battles",
            "Special 'Active Player' status effects",
            "Fitness achievement progress"
          ],
          "weekly_rewards": [
            "Bonus card packs for meeting weekly goals",
            "Exclusive fitness-themed cosmetic items",
            "Access to fitness-only quests and challenges",
            "Leaderboard rankings for most active players"
          ],
          "long_term_benefits": [
            "Fitness achievements with permanent character bonuses",
            "Unlock fitness-exclusive content and areas",
            "Special recognition in guild and global leaderboards",
            "Real-world fitness improvement tracking and celebration"
          ]
        }
      },
      "common_questions": {
        "Do I need a fitness tracker?": "Nope! Your phone can track your steps automatically. Fitness trackers just give you more detailed data and might be more accurate, but they're totally optional!",
        "What if I can't walk much due to health issues?": "The game is designed to be inclusive! You can still progress through quests, battles, social activities, and other non-fitness features. Plus, any activity counts - even small movements help!",
        "Does the app drain my phone battery with fitness tracking?": "We've optimized the app to be battery-friendly! The fitness tracking runs in the background efficiently, and you can adjust settings to balance accuracy with battery life."
      }
    },

    "ar_features": {
      "name": "Augmented Reality Experiences",
      "description": "Magical AR experiences that bring the game world into your real environment",
      "simple_explanation": "Point your phone camera around you and watch as dragons, treasures, and magical portals appear in your real world! It's like having X-ray vision for adventure! 📱✨",
      "features": {
        "ar_encounters": {
          "explanation": "Special creatures and objects that appear in your camera view at certain locations",
          "types": [
            "Quest Guardians - Bosses that appear at quest locations",
            "Treasure Chests - Hidden loot that appears near landmarks", 
            "Magical Portals - Gateways to special in-game areas",
            "Friendly NPCs - Characters who give hints and lore",
            "Card Manifestations - Your cards come to life in AR!"
          ],
          "interaction_methods": [
            "Tap to interact with AR objects",
            "Use gestures to cast spells and abilities",
            "Move around to get better angles and find hidden elements",
            "Take photos and videos to share with friends"
          ]
        },
        "ar_battles": {
          "explanation": "Fight epic battles where your cards and enemies appear in your real space!",
          "features": [
            "Summon creature cards that appear on your table or floor",
            "Cast spell effects that fill your room with magic",
            "Dodge and move around to avoid enemy attacks",
            "Use your environment as part of the battle strategy"
          ]
        },
        "ar_customization": {
          "explanation": "Personalize your AR experience with custom effects and settings",
          "options": [
            "Adjust AR object size and brightness",
            "Choose different visual themes and effects",
            "Set AR comfort levels for motion sensitivity",
            "Save favorite AR moments as screenshots or videos"
          ]
        }
      },
      "common_questions": {
        "What phones support AR features?": "Most modern smartphones support our AR features! iPhones with iOS 12+ and Android phones with ARCore support work great. The app will let you know if your device is compatible.",
        "Do I need good lighting for AR?": "AR works best in good lighting, but our system is pretty forgiving! Bright indoor lighting or outdoor daylight gives the best results, but it can work in various conditions.",
        "Can I use AR features indoors?": "Absolutely! In fact, many AR experiences work great indoors. You just need enough space to move around safely and point your camera at different surfaces."
      }
    },

    "weather_system": {
      "name": "Weather Integration",
      "description": "Real-world weather conditions affect your in-game experience and bonuses",
      "simple_explanation": "Mother Nature becomes your gaming partner! Sunny days might boost your magic, while rainy weather could help your nature spells grow stronger! 🌦️⚡",
      "features": {
        "weather_effects": {
          "sunny": {
            "bonuses": ["+20% XP from outdoor activities", "Fire spells deal extra damage", "Solar-powered equipment charges faster"],
            "special_events": ["Solar festivals", "Desert exploration bonuses", "Light-based puzzles appear"]
          },
          "rainy": {
            "bonuses": ["+30% water spell effectiveness", "Plant growth quests available", "Enhanced tracking of water creatures"],
            "special_events": ["Rainbow treasure hunts", "Storm giant encounters", "Reflection puzzles in puddles"]
          },
          "snowy": {
            "bonuses": ["Ice spells gain power", "Winter creatures appear more often", "Special cold-weather gear effectiveness"],
            "special_events": ["Snowman building quests", "Ice castle discoveries", "Winter holiday celebrations"]
          },
          "cloudy": {
            "bonuses": ["Balanced conditions for all activities", "Mystery events more likely", "Cloud-reading fortune telling"],
            "special_events": ["Sky ship sightings", "Weather prediction minigames", "Atmospheric anomalies"]
          },
          "stormy": {
            "bonuses": ["Lightning spells supercharged", "Storm creature encounters", "Wind-powered travel bonuses"],
            "special_events": ["Epic storm boss battles", "Thunder god blessings", "Tornado treasure vaults"]
          }
        },
        "seasonal_events": {
          "spring": ["Flower gathering quests", "New life celebration events", "Growth and renewal themes"],
          "summer": ["Solar-powered adventures", "Beach and water activities", "Long daylight exploration bonuses"],
          "autumn": ["Harvest festivals", "Leaf collection challenges", "Preparation for winter quests"],
          "winter": ["Snow and ice activities", "Holiday celebrations", "Cozy indoor social events"]
        },
        "location_based_weather": {
          "explanation": "The game uses your real location's current weather conditions",
          "features": [
            "Real-time weather data integration",
            "Hourly weather updates affect game world",
            "Weather forecasts help plan your adventures",
            "Historical weather patterns unlock special content"
          ]
        }
      },
      "common_questions": {
        "What if the weather is bad for days?": "Don't worry! Every weather type has its own bonuses and special content. Plus, there are always indoor activities and quests that don't depend on weather!",
        "Can I play during extreme weather?": "Safety first! The app will remind you to stay safe during severe weather warnings. You can still enjoy indoor features while staying cozy and safe.",
        "Does weather affect all parts of the game?": "Weather mainly affects outdoor activities, special events, and certain spell/ability bonuses. Core features like battles, guild chat, and deck building work the same regardless of weather!"
      }
    },

    "audio_system": {
      "name": "Spatial Audio & Music System",
      "description": "Immersive 3D audio that responds to your environment and actions",
      "simple_explanation": "Put on headphones and feel like you're really inside the game world! Sounds come from different directions, music changes based on where you are, and everything feels incredibly real! 🎧🎵",
      "features": {
        "spatial_audio": {
          "explanation": "3D positioned sound that makes audio feel like it's coming from specific locations in space",
          "examples": [
            "Footsteps sound like they're coming from behind you",
            "Dragon roars echo from the direction of AR creatures",
            "Guild member voices positioned around you in virtual space",
            "Environmental sounds match your real surroundings"
          ]
        },
        "adaptive_music": {
          "explanation": "Dynamic soundtrack that changes based on your activities and location",
          "music_types": [
            "Exploration - Peaceful, ambient music for walking and questing",
            "Battle - Intense, rhythmic music that matches combat pace",
            "Social - Friendly, upbeat music for guild interactions",
            "Discovery - Mysterious, magical music for finding secrets",
            "Achievement - Triumphant fanfares for accomplishments"
          ]
        },
        "environmental_audio": {
          "explanation": "Realistic sound effects that match your real-world environment",
          "features": [
            "Park sounds when you're in green spaces",
            "City ambience when you're downtown",
            "Water sounds near rivers, lakes, or oceans",
            "Weather sounds that match current conditions"
          ]
        }
      },
      "common_questions": {
        "Do I need special headphones?": "Any headphones work, but stereo headphones or earbuds give you the best spatial audio experience! Even basic earbuds can provide amazing immersion.",
        "Can I play without sound?": "Of course! The game works great in silent mode too. You can even enable visual indicators that replace audio cues for accessibility.",
        "Does the audio drain battery?": "Our audio system is optimized for efficiency! You can adjust audio quality settings to balance immersion with battery life."
      }
    }
  };

  /// Feature explanations organized by difficulty level
  static const Map<String, List<String>> explanationLevels = {
    "beginner": [
      "Use simple, friendly language",
      "Include emoji and fun comparisons", 
      "Focus on 'what' rather than 'how'",
      "Give encouraging, positive tone",
      "Use real-world analogies"
    ],
    "intermediate": [
      "Provide more detailed mechanics",
      "Explain strategy and optimization tips",
      "Include multiple approaches to goals",
      "Reference interconnected systems",
      "Offer advanced techniques"
    ],
    "expert": [
      "Cover complex interactions and edge cases",
      "Discuss meta-game strategies", 
      "Explain mathematical formulas and calculations",
      "Reference technical implementation details",
      "Include competitive optimization advice"
    ]
  };

  /// Common user questions and helpful responses
  static const Map<String, String> commonQuestions = {
    "how do i get started": "Welcome to Realm of Valor! 🎉 Start by creating your character, complete the tutorial to learn the basics, and then try your first quest. Don't worry about making mistakes - every adventure teaches you something new!",
    
    "what should i do first": "Great question! After creating your character, I recommend: 1) Complete the tutorial ✅ 2) Try a nearby beginner quest 🗺️ 3) Scan your first card (if you have one) 📱 4) Join a beginner-friendly guild 👥. Take it one step at a time!",
    
    "how do i get better cards": "There are lots of ways to build your collection! 💪 Complete quests and battles for card packs, purchase physical cards in stores, trade with friends, join guild events, and keep playing daily for login bonuses!",
    
    "why am i losing battles": "Battles can be tricky at first! 🤔 Try these tips: Build a balanced deck with offense and defense, practice against AI enemies first, watch your energy usage, and don't be afraid to ask guild members for deck advice. Every loss teaches you something!",
    
    "how does fitness tracking work": "Your real-world steps power your character! 🏃‍♀️ Just keep your phone with you (or wear a fitness tracker) and the app automatically converts your steps into XP. 100 steps = 1 XP, plus bonus rewards for daily goals!",
    
    "can i play without walking": "Absolutely! 😊 While fitness activities give great bonuses, you can enjoy battles, guild chat, deck building, AR experiences, and many quests without walking. The game is designed to be fun for everyone!",
    
    "what are guilds for": "Guilds are your gaming family! 👨‍👩‍👧‍👦 Join one to make friends, get help with quests, participate in group activities, access guild-only content, and have people to chat with. It makes the game way more fun!",
    
    "how do i use ar": "AR (Augmented Reality) is amazing! 📱✨ Just point your camera around when you're at quest locations or during special events. Dragons, treasures, and magical effects will appear in your real world through your phone screen!",
    
    "is my data safe": "Your privacy and safety are our top priority! 🔒 We use bank-level encryption, never share personal data without permission, and you control what information to share. Check our privacy policy for full details!",
    
    "how do i report bugs": "Thanks for helping make the game better! 🛠️ Use the 'Report Issue' button in settings, or tell me about problems and I can help troubleshoot and report them to the development team!"
  };

  /// Contextual help suggestions based on user situation
  static const Map<String, Map<String, dynamic>> contextualHelp = {
    "new_player": {
      "suggestions": [
        "Complete the character creation tutorial",
        "Try your first quest nearby",
        "Join a beginner-friendly guild",
        "Scan your first physical card"
      ],
      "tips": [
        "Don't worry about making perfect choices early on",
        "Explore different features to find what you enjoy",
        "Ask questions in guild chat - players love to help!"
      ]
    },
    "stuck_in_battle": {
      "suggestions": [
        "Review your deck composition for balance",
        "Practice against easier AI opponents",
        "Ask guild members for deck-building advice",
        "Try different combat strategies"
      ],
      "tips": [
        "Watch your energy usage during battles",
        "Save powerful cards for the right moment",
        "Consider your opponent's possible moves"
      ]
    },
    "low_activity": {
      "suggestions": [
        "Set daily step goals that feel achievable",
        "Find quests that motivate you to explore",
        "Try the AR features for fun motivation",
        "Connect with active guild members"
      ],
      "tips": [
        "Every step counts - start small and build up",
        "Make it social by meeting friends for quests",
        "Celebrate small victories and progress"
      ]
    }
  };

  /// Feature interconnections - how systems work together
  static const Map<String, List<String>> systemConnections = {
    "character_progression": [
      "Fitness tracking provides XP for leveling",
      "Quest completion grants experience and rewards", 
      "Battle victories increase character stats",
      "Card collection enhances character abilities"
    ],
    "social_integration": [
      "Guild membership enables group quests",
      "Friend networks facilitate card trading",
      "Social features enhance AR experiences",
      "Community events require guild participation"
    ],
    "real_world_integration": [
      "GPS location enables quest discovery",
      "Weather conditions affect game bonuses",
      "Fitness data drives character growth",
      "Physical cards unlock digital content"
    ]
  };

  /// Get feature information by name
  static Map<String, dynamic>? getFeatureInfo(String featureName) {
    return knowledgeBase[featureName.toLowerCase().replaceAll(' ', '_')];
  }

  /// Get contextual help based on user state
  static Map<String, dynamic>? getContextualHelp(String context) {
    return contextualHelp[context];
  }

  /// Search for features by keyword
  static List<String> searchFeatures(String query) {
    final results = <String>[];
    final queryLower = query.toLowerCase();
    
    knowledgeBase.forEach((key, value) {
      if (key.contains(queryLower) || 
          value['name'].toString().toLowerCase().contains(queryLower) ||
          value['description'].toString().toLowerCase().contains(queryLower)) {
        results.add(key);
      }
    });
    
    return results;
  }

  /// Get explanation for a specific difficulty level
  static String getExplanationForLevel(String feature, String level) {
    final featureInfo = getFeatureInfo(feature);
    if (featureInfo == null) return "I don't have information about that feature yet.";
    
    switch (level) {
      case 'beginner':
        return featureInfo['simple_explanation'] ?? featureInfo['description'];
      case 'intermediate':
      case 'expert':
        return featureInfo['description'] ?? featureInfo['simple_explanation'];
      default:
        return featureInfo['simple_explanation'] ?? featureInfo['description'];
    }
  }

  /// Get version information
  static Map<String, String> getVersionInfo() {
    return {
      'version': version,
      'lastUpdated': lastUpdated,
      'totalFeatures': knowledgeBase.length.toString(),
      'totalQuestions': commonQuestions.length.toString()
    };
  }
}