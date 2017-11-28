-- Table: Last Update Hash
CREATE TABLE FileChecksum (
    filename TEXT PRIMARY KEY,
    hex TEXT NOT NULL ON CONFLICT REPLACE
);

-- Table: Cycle
CREATE TABLE Cycle (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE COLLATE NOCASE,
    position INTEGER NOT NULL,
    size INTEGER NOT NULL DEFAULT 0
);

-- Table: Pack
CREATE TABLE Pack (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE COLLATE NOCASE,
    position INTEGER NOT NULL,
    size INTEGER NOT NULL DEFAULT 0,
    cycle_id INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES Cycle(id)
);

-- Table: Investigator
CREATE TABLE Investigator (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    position INTEGER NOT NULL,
    subname TEXT NOT NULL DEFAULT '',
    health INTEGER NOT NULL,
    sanity INTEGER NOT NULL,
    faction_id INTEGER NOT NULL,
    pack_id TEXT NOT NULL,

    front_text TEXT NOT NULL,
    back_text TEXT NOT NULL,

    agility INTEGER NOT NULL DEFAULT 0,
    combat INTEGER NOT NULL DEFAULT 0,
    intellect INTEGER NOT NULL DEFAULT 0,
    willpower INTEGER NOT NULL DEFAULT 0,

    traits TEXT,

    front_flavor TEXT,
    back_flavor TEXT,

    illustrator TEXT,

    FOREIGN KEY (pack_id) REFERENCES Pack(id)
);
CREATE INDEX IF NOT EXISTS idx_inv_pack_id ON Investigator(pack_id);

-- Table: Card
CREATE TABLE Card (
    id INTEGER PRIMARY KEY,
    position INTEGER NOT NULL,
    level INTEGER NOT NULL DEFAULT 0,
    cost INTEGER NOT NULL DEFAULT 0,
    quantity INTEGER NOT NULL DEFAULT 2,
    deck_limit INTEGER NOT NULL DEFAULT 2,
    name TEXT NOT NULL,
    subname TEXT,
    is_unique INTEGER NOT NULL DEFAULT 0,
    text TEXT NOT NULL DEFAULT '',

    restricted INTEGER NOT NULL DEFAULT 0,

    type_id INTEGER NOT NULL,
    subtype_id INTEGER,
    faction_id INTEGER NOT NULL,
    pack_id TEXT NOT NULL,
    asset_slot_id INTEGER,

    traits TEXT,

    skill_agility INTEGER NOT NULL DEFAULT 0,
    skill_combat INTEGER NOT NULL DEFAULT 0,
    skill_intellect INTEGER NOT NULL DEFAULT 0,
    skill_willpower INTEGER NOT NULL DEFAULT 0,
    skill_wild INTEGER NOT NULL DEFAULT 0,

    health INTEGER NOT NULL DEFAULT 0,
    sanity INTEGER NOT NULL DEFAULT 0,

    investigator_id INTEGER,

    flavor_text TEXT,
    illustrator TEXT,
    double_sided INTEGER NOT NULL DEFAULT 0,

    enemy_fight INTEGER NOT NULL DEFAULT 0,
    enemy_evade INTEGER NOT NULL DEFAULT 0,
    enemy_health INTEGER NOT NULL DEFAULT 0,
    enemy_damage INTEGER NOT NULL DEFAULT 0,
    enemy_horror INTEGER NOT NULL DEFAULT 0,
    enemy_health_per_investigator INTEGER NOT NULL DEFAULT 0,

    internal_code TEXT NOT NULL,

    FOREIGN KEY (pack_id) REFERENCES Pack(id),
    FOREIGN KEY (investigator_id) REFERENCES Investigator(id)
);

CREATE INDEX idx_card_pack_id ON Card(pack_id);
CREATE INDEX idx_card_investigator_id ON Card(investigator_id);

-- Table: CardFTS
CREATE VIRTUAL TABLE IF NOT EXISTS CardFTS USING fts4 (
    id, keywords, tokenize = 'porter'
);

CREATE TABLE IF NOT EXISTS Deck (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    investigator_id INTEGER NOT NULL,
    creation_date DATETIME NOT NULL,
    update_date DATETIME NOT NULL,
    FOREIGN KEY (investigator_id) REFERENCES Investigator(id)
);

CREATE TABLE IF NOT EXISTS DeckCard (
    deck_id INTEGER NOT NULL,
    card_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 2,
    PRIMARY KEY(deck_id, card_id),
    FOREIGN KEY(deck_id) REFERENCES Deck(id) ON DELETE CASCADE,
    FOREIGN KEY(card_id) REFERENCES Card(id) ON DELETE CASCADE
);

--
-- Chaos Bag
--

-- Table: Difficulty
CREATE TABLE IF NOT EXISTS Difficulty (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

-- Table: ChaosBag
CREATE TABLE IF NOT EXISTS ChaosBag (
    id INTEGER PRIMARY KEY,
    plus1 INTEGER DEFAULT 0,
    zero INTEGER DEFAULT 0,
    minus1 INTEGER DEFAULT 0,
    minus2 INTEGER DEFAULT 0,
    minus3 INTEGER DEFAULT 0,
    minus4 INTEGER DEFAULT 0,
    minus5 INTEGER DEFAULT 0,
    minus6 INTEGER DEFAULT 0,
    minus7 INTEGER DEFAULT 0,
    minus8 INTEGER DEFAULT 0,
    skull INTEGER DEFAULT 0,
    autofail INTEGER DEFAULT 0,
    tablet INTEGER DEFAULT 0,
    cultist INTEGER DEFAULT 0,
    eldersign INTEGER DEFAULT 0,
    elderthing INTEGER DEFAULT 0
);

-- Table: Campaign
CREATE TABLE IF NOT EXISTS Campaign (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
);

-- Table: Scenario
CREATE TABLE IF NOT EXISTS Scenario (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    difficulty_id INTEGER NOT NULL,
    FOREIGN KEY (difficulty_id) REFERENCES Difficulty(id)
);
CREATE INDEX IF NOT EXISTS idx_scenario_difficulty_id ON Scenario(difficulty_id);

-- Table: ScenarioChaosBag
CREATE TABLE IF NOT EXISTS ScenarioChaosBag (
    scenario_id INTEGER NOT NULL,
    difficulty_id INTEGER NOT NULL,
    chaos_bag_id INTEGER NOT NULL,
    PRIMARY KEY (scenario_id, difficulty_id),
    FOREIGN KEY (scenario_id) REFERENCES Scenario(id),
    FOREIGN KEY (difficulty_id) REFERENCES Difficulty(id),
    FOREIGN KEY (chaos_bag_id) REFERENCES ChaosBag(id)
);
CREATE INDEX IF NOT EXISTS idx_scenario_chaos_bag_scenario_id ON ScenarioChaosBag(scenario_id);
CREATE INDEX IF NOT EXISTS idx_scenario_chaos_bag_difficulty_id ON ScenarioChaosBag(difficulty_id);
CREATE INDEX IF NOT EXISTS idx_scenario_chaos_bag_chaos_bag_id ON ScenarioChaosBag(chaos_bag_id);

-- Table: CampaignScenario
CREATE TABLE IF NOT EXISTS CampaignScenario (
    campaign_id INTEGER NOT NULL,
    scenario_id INTEGER NOT NULL,
    PRIMARY KEY (campaign_id, scenario_id),
    FOREIGN KEY (campaign_id) REFERENCES Campaign(id),
    FOREIGN KEY (scenario_id) REFERENCES Scenario(id)
);
CREATE INDEX IF NOT EXISTS idx_campaign_scenario_campaign_id ON CampaignScenario(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_scenario_scenario_id ON CampaignScenario(scenario_id);

