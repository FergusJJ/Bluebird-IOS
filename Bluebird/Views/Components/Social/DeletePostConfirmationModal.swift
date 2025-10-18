import SwiftUI

struct DeletePostConfirmationModal: View {
    let postID: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color.themeSecondary)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(Color.themeAccent)
                    .padding(.bottom, 4)

                Text("Remove Post?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themePrimary)

                Text("This will permanently delete your post. This action cannot be undone.")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 10)

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text("Yes, Remove Post")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(12)
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themeElement)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.themeBackground)
        .cornerRadius(20)
        .padding(.horizontal, 30)
    }

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)

        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}
