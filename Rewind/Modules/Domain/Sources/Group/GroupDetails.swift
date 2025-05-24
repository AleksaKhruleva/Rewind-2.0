public struct GroupDetails {
    public let group: GroupResponse
    public let members: [GroupMemberResponse]
    
    public init(group: GroupResponse, members: [GroupMemberResponse]) {
        self.group = group
        self.members = members
    }
}
