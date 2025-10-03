struct ConnectedAccountDetails: Decodable {
    let display_name: String
    let email: String
    let scopes: String
    let account_url: String
    let product: String // premium / free
    let spotify_user_id: String
}
