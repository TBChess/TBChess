import requests
import json
import random
import time

# Configuration
API_URL = "http://localhost:8080/round"
NUM_REQUESTS = 10
NUM_PLAYERS = 25
NUM_ROUNDS = 5

def generate_players(num_players):
    """Generate players with random ELO ratings"""
    players = []
    for i in range(1, num_players + 1):
        players.append({
            "name": f"p{i}",
            "elo": round(random.uniform(600, 2000), 0)
        })
    return players

def generate_games(players, num_rounds, pairs):
    """Generate different game result combinations"""
    games = []
    for p in pairs:
        result = random.randint(0, 2) / 2.0
        g = {
            'white': p['white'],
        }

        if 'bye' in p:
            result = 1.0
            g['bye'] = True
        else:
            g['black'] = p['black']
        
        g['result'] = result
        
        games.append(g)

    return games

def stress_test_endpoint(url, num_requests=100):
    """Stress test the chess pairing endpoint"""
    
    print(f"Starting stress test with {num_requests} requests...")
    print(f"Target URL: {url}")
    
    start_time = time.time()
    
    for i in range(num_requests):
        pairs = []
        game_hist = []
        players = generate_players(NUM_PLAYERS)
        

        for r in range(1, NUM_ROUNDS + 1):
            payload = {
                "rounds": NUM_ROUNDS,
                "players": players,
                "games": game_hist
            }
            data = {"data": json.dumps(payload)}

            try:
                response = requests.post(url, data=data, timeout=30)
            except Exception as e:
                print(e)
                exit(1)
            
            if response.status_code == 200:
                try:
                    res = response.json()
                    if isinstance(res, list) and len(res) > 0:
                        expected_rounds = len(players) // 2 if len(players) % 2 == 0 else len(players) // 2 + 1
                        if len(res) != expected_rounds:
                            print(f"Invalid round numbers generated: {len(res)}")
                            exit(1)
                        pairs = res
                        game_hist += [generate_games(players, r, pairs)]
                        scores = {}
                        stats = {}

                        for rnd in game_hist:
                            for g in rnd:
                                result = g['result']
                                w = g['white']
                                b = None
                                bye = 'bye' in g and g['bye']
                                if 'black' in g:
                                    b = g['black']
                                if not w in scores:
                                    scores[w] = 0
                                if not w in stats:
                                    stats[w] = {
                                        'byes': 0,
                                        'white': 0,
                                        'black': 0,
                                    }
                                    for p in [p['name'] for p in players if p['name'] != w]:
                                        stats[w][p] = 0
                                    
                                if b is not None and not(b in scores):
                                    scores[b] = 0
                                    stats[b] = {
                                        'byes': 0,
                                        'white': 0,
                                        'black': 0,
                                    }
                                    for p in [p['name'] for p in players if p['name'] != b]:
                                        stats[b][p] = 0

                                if bye:
                                    scores[w] += 1
                                    stats[w]['byes'] += 1

                                else:
                                    stats[w][b] += 1
                                    stats[b][w] += 1
                                    stats[w]['white'] += 1
                                    stats[b]['black'] += 1

                                    if result == 1.0:
                                        scores[w] += 1
                                    elif result == 0:
                                        scores[b] += 1

                                    elif result == 0.5:
                                        scores[w] += 0.5
                                        scores[b] += 0.5                                

                        for p in pairs:
                            b = p.get('black', 'bye')
                            if b == 'bye':
                                print("%s (%s, W: %s, B: %s) vs %s (-)" % (p['white'], scores[p['white']], stats[p['white']]['white'], stats[p['white']]['black'], b))
                            else:
                                print("%s (%s, W: %s, B: %s) vs %s (%s, W: %s, B: %s)" % (p['white'], scores[p['white']], stats[p['white']]['white'], stats[p['white']]['black'], 
                                                                                          b, scores[b], stats[p['black']]['white'], stats[p['black']]['black']))
                        # print(stats)
                    else:
                        print(f"Invalid response format: {res}")
                        exit(1)
                except json.JSONDecodeError:
                    print("Response is not valid JSON")
                    exit(1)
            else:
                print(f"HTTP {response.status_code}: {response.text}")
                exit(1)

            
            print(f"✓ Round: {r}")

    end_time = time.time()
    
    print("OK")

if __name__ == "__main__":
    stress_test_endpoint(API_URL, NUM_REQUESTS)