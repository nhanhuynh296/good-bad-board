from enum import IntEnum, auto
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class Elo(IntEnum):
    C2 = auto()  # Newbie
    C1 = auto()  # Trinity
    B2 = auto()  # Ryan
    B1 = auto()  # Wei
    A2 = auto()  # Nathan
    A1 = auto()  # Justin
    S2 = auto()  # Josh
    S1 = auto()  #


class Player(BaseModel):
    name: str
    elo: Elo
    id: UUID = Field(default_factory=uuid4)
    ...

    def __hash__(self):
        return hash(self.id)

    def __str__(self):
        return f"{self.name:15s} ({self.elo})"
