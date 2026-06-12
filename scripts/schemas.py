"""
Pydantic schemas for D&D adventure entities.
Validation layer between hand-authored JSON and ChromaDB ingestion.
"""
from __future__ import annotations

from typing import Literal, Optional
from pydantic import BaseModel, Field, field_validator


EntityType = Literal[
    "adventure_overviews",
    "hooks",
    "rooms",
    "npcs",
    "monsters",
    "encounters",
    "puzzles",
    "clues",
    "treasures",
    "items",
]


class BaseEntity(BaseModel):
    """Fields every entity must have."""
    id: str = Field(..., description="Stable unique id, e.g. room_m3_library")
    type: EntityType
    name: str
    source_section: str = Field(..., description="Where in the PDF, e.g. 'M3. LIBRARY, p.19'")
    full_text: str = Field(..., description="Verbatim or near-verbatim text for the DM")
    summary: str = Field(..., max_length=500)
    keywords: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list, description="Filter tags: combat, trap, puzzle_solution, etc.")
    dm_notes: str = Field(default="", description="DM-authored notes, empty initially")
    version: int = Field(default=1)

    @field_validator("id")
    @classmethod
    def id_format(cls, v: str) -> str:
        if not v or " " in v or v != v.lower():
            raise ValueError(f"id must be lowercase, no spaces: got {v!r}")
        return v

class clues(BaseModel):
    id: str
    type: Literal["clue"] = "clue"
    name: str
    source_section: str
    full_text: str
    summary: str
    keywords: list[str]
    tags: list[str]
    location_room_id: str
    points_to: list[str]
    discovery_method: str


class AbilityScores(BaseModel):
    str_: int = Field(..., alias="STR")
    dex: int = Field(..., alias="DEX")
    con: int = Field(..., alias="CON")
    int_: int = Field(..., alias="INT")
    wis: int = Field(..., alias="WIS")
    cha: int = Field(..., alias="CHA")

    model_config = {"populate_by_name": True}


class StatBlockAction(BaseModel):
    name: str
    description: str


class StatBlock(BaseModel):
    """D&D 5e stat block. Use for monster and npc entities."""
    size: str = Field(default="", description="Tiny, Small, Medium, Large, Huge, Gargantuan")
    creature_type: str = Field(default="", description="construct, humanoid, fiend, etc.")
    alignment: str = Field(default="")
    armor_class: int = Field(default=0)
    armor_class_source: str = Field(default="", description="natural armor, leather, etc.")
    hit_points: int = Field(default=0)
    hp_formula: str = Field(default="", description="e.g. 4d8+4")
    speed: dict[str, int] = Field(default_factory=dict, description="walk/fly/swim/burrow ft.")
    abilities: Optional[AbilityScores] = None
    saving_throws: dict[str, int] = Field(default_factory=dict)
    skills: dict[str, int] = Field(default_factory=dict)
    damage_vulnerabilities: list[str] = Field(default_factory=list)
    damage_resistances: list[str] = Field(default_factory=list)
    damage_immunities: list[str] = Field(default_factory=list)
    condition_immunities: list[str] = Field(default_factory=list)
    senses: list[str] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    challenge_rating: str = Field(default="", description="Use string for fractions: '1/4', '1/2', '1'")
    xp: int = Field(default=0)
    proficiency_bonus: int = Field(default=2)
    traits: list[StatBlockAction] = Field(default_factory=list)
    actions: list[StatBlockAction] = Field(default_factory=list)
    legendary_actions: list[StatBlockAction] = Field(default_factory=list)
    reactions: list[StatBlockAction] = Field(default_factory=list)


class AdventureOverview(BaseEntity):
    type: Literal["adventure_overview"] = "adventure_overview"
    party_level: str = Field(default="", description="e.g. '1st-level'")
    setting: str = Field(default="")
    themes: list[str] = Field(default_factory=list)


class StoryHook(BaseEntity):
    type: Literal["story_hook"] = "story_hook"
    hook_kind: str = Field(default="", description="village_in_need, research, rumor, etc.")
    leads_to: list[str] = Field(default_factory=list, description="entity ids this hook points to")


class Room(BaseEntity):
    type: Literal["room"] = "room"
    room_id: str = Field(..., description="Original identifier like 'M3'")
    level: str = Field(default="", description="upper/middle/lower")
    read_aloud_text: str = Field(default="", description="Box text read to players verbatim")
    connected_rooms: list[str] = Field(default_factory=list, description="other room_ids")
    contains_entity_ids: list[str] = Field(default_factory=list)
    dcs: list[dict] = Field(default_factory=list, description="[{check: 'DC 15 Dex save', purpose: '...'}]")
    light: str = Field(default="")


class NPC(BaseEntity):
    type: Literal["npc"] = "npc"
    role: str = Field(default="")
    alignment: str = Field(default="")
    location_room_ids: list[str] = Field(default_factory=list)
    stat_block: Optional[StatBlock] = None
    mm_reference: str = Field(default="", description="If using a Monster Manual stat block")


class Monster(BaseEntity):
    type: Literal["monster"] = "monster"
    location_room_ids: list[str] = Field(default_factory=list)
    quantity: int = Field(default=1)
    stat_block: Optional[StatBlock] = None
    mm_reference: str = Field(default="", description="e.g. 'Monster Manual p. 220' if using MM block")
    modifications: str = Field(default="", description="Adventure-specific changes to the base stat block")


class Encounter(BaseEntity):
    type: Literal["encounter"] = "encounter"
    location_room_id: str = Field(default="")
    monsters_involved: list[str] = Field(default_factory=list, description="monster entity ids")
    trigger: str = Field(default="")
    tactics: str = Field(default="")


class Puzzle(BaseEntity):
    type: Literal["puzzle"] = "puzzle"
    location_room_id: str = Field(default="")
    solution: str = Field(..., description="Preserve EXACTLY from source")
    dc: str = Field(default="", description="e.g. 'DC 13 Intelligence (Arcana)'")
    unlocks: list[str] = Field(default_factory=list, description="entity ids unlocked by solving")


class Clue(BaseEntity):
    type: Literal["clue"] = "clue"
    location_room_id: str = Field(default="")
    points_to: list[str] = Field(default_factory=list, description="entity ids this clue reveals")
    discovery_method: str = Field(default="", description="passive Perception 12, 30 min search, etc.")


class Treasure(BaseEntity):
    type: Literal["treasure"] = "treasure"
    location_room_id: str = Field(default="")
    value_gp: Optional[int] = None
    magic_item: bool = Field(default=False)


class Item(BaseEntity):
    type: Literal["item"] = "item"
    location_room_id: str = Field(default="")
    magical: bool = Field(default=False)
    properties: str = Field(default="")


ENTITY_MODELS: dict[str, type[BaseEntity]] = {
    "adventure_overview": AdventureOverview,
    "story_hook": StoryHook,
    "room": Room,
    "npc": NPC,
    "monster": Monster,
    "encounter": Encounter,
    "puzzle": Puzzle,
    "clue": Clue,
    "treasure": Treasure,
    "item": Item,
}


def parse_entity(raw: dict) -> BaseEntity:
    """Dispatch raw dict to the correct pydantic model by `type` field."""
    etype = raw.get("type")
    if etype not in ENTITY_MODELS:
        raise ValueError(f"Unknown entity type: {etype!r}. Must be one of {list(ENTITY_MODELS)}")
    return ENTITY_MODELS[etype].model_validate(raw)
