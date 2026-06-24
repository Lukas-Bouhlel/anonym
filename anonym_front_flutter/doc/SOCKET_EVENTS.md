# Socket.IO Events

Reference: `lib/services/socket_service.dart` et `lib/providers/realtime_providers.dart`.

## Connexion

1. Transport: `websocket`, fallback `polling`.
2. Auth:
   - cookies de session via `ApiClient.buildSocketAuthHeaders()`.

## Evenements sortants (client -> serveur)

1. `joinChannel`
   - payload: `{ channelId, userId }`
2. `leaveChannel`
   - payload: `{ channelId, userId }`
3. `privateMessage`
   - payload: `{ senderId, content, channelId }`
4. `location:sync`
   - demande snapshot des positions live
5. `location:update`
   - payload: `{ userId, username, avatar, lat, lng, accuracy, updatedAt }`
6. `location:stop`
   - payload: `{ userId }`

## Evenements entrants (serveur -> client)

## Messaging / social

1. `newMessage` -> nouveau message channel.
2. `messageError` -> erreur de publication message.
3. `friendRequestReceived`
4. `friendRequestSent`
5. `friendRequestResponded`
6. `friendRequestCancelled`
7. `friendshipBlocked`
8. `friendshipUnblocked`
9. `friendshipDeleted`
10. `friendsStateUpdated`
11. `channelInvited`
12. `channelMemberRemoved`
13. `channelUpdated`
14. `groupUpdated` (alias traite comme `channelUpdated`)
15. `userProfileUpdated`
16. `presenceUpdated`

## Geolocalisation live

Snapshots (alias supportes):

1. `location:snapshot`
2. `location:usersSnapshot`
3. `locations:snapshot`

Updates (alias supportes):

1. `location:update`
2. `location:userMoved`
3. `locations:update`

Removals (alias supportes):

1. `location:remove`
2. `location:userLeft`
3. `locations:remove`

## Evenements de transport

1. `connect`
2. `disconnect`
3. `connect_error`
4. `reconnect`

Sur `connect`/`reconnect`, le client redemande automatiquement un snapshot live.
