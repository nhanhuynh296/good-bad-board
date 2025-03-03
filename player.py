from dataclasses import dataclass, field
from uuid import UUID, uuid4



@dataclass
class Player:
    name: str
    elo: int
    id: UUID = field(default_factory=uuid4)
    ...
