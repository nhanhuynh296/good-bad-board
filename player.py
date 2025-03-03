from dataclasses import dataclass, field
from uuid import UUID, uuid4


@dataclass
class Player:
    name: str
    elo: int
    id: UUID = field(default_factory=uuid4)
    ...

    def __hash__(self):
        return hash(self.id)

    def __str__(self):
        return f"{self.name} ({self.elo})"

    def __repr__(self):
        return f"Player(name={self.name}, elo={self.elo})"
