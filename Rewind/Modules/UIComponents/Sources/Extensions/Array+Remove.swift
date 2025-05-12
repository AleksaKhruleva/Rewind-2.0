extension Array {
  @discardableResult
  public mutating func tryRemove(at index: Index) -> Element? {
    guard indices.contains(index) else { return nil }
    
    return remove(at: index)
  }
}
