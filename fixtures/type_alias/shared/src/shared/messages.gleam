import shared/item.{type Item, type Priority}

/// Alias to a primitive
pub type Score =
  Int

/// Alias to a custom type from another module
pub type UserPriority =
  Priority

/// Alias wrapping a container with a custom type inside
pub type ItemList =
  List(Item)

pub type MsgFromClient {
  GetScore
  GetItems
  GetPriority
}

pub type MsgFromServer {
  GotScore(Score)
  GotItems(ItemList)
  GotPriority(UserPriority)
}
