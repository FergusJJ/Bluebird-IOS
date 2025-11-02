import SwiftUI

// this probablt belongs to SocialFeedListView
struct UnifiedFeedRowView: View {
    let unifiedFeedItem: UnifiedFeedItem
    let currentUserID: String?
    let onEntityTap: () -> Void
    let onProfileTap: () -> Void
    let onDeleteTap: (() -> Void)?

    var body: some View {
        switch unifiedFeedItem.content_type {
        case .repost:
            RepostInUnifiedFeedView(
                unifiedFeedItem: unifiedFeedItem,
                currentUserID: currentUserID,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap,
                onDeleteTap: onDeleteTap
            )

        case .highlightLoving, .highlightDiscovery:
            HighlightRowView(
                unifiedFeedItem: unifiedFeedItem,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap
            )

        case .highlightMilestone:
            MilestoneRowView(
                unifiedFeedItem: unifiedFeedItem,
                currentUserID: currentUserID,
                onEntityTap: onEntityTap,
                onProfileTap: onProfileTap
            )
        }
    }
}
