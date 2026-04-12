//// SETUP. Extend when you add new injected values that RPC functions
//// can pull out of the Session.
////
//// Libero `/// @inject` functions.
////
//// Every function in this module annotated with `/// @inject` defines
//// a value that libero can plumb into RPC functions automatically. The
//// rule is:
////
////   1. The inject function takes a single parameter, the Session
////      value the WebSocket handler builds for the connection.
////   2. It returns whatever value should be injected (a database
////      connection, a user record, an id, anything).
////   3. Any `@rpc` function whose first labelled parameter has the
////      same name as the inject function gets that value passed in
////      automatically at dispatch time.
////
//// Inject parameters never appear on the wire. The client stub doesn't
//// know they exist, so the client can't fake or override them. These
//// are server-trust values derived from the Session.
////
//// Libero scans every file under the server scan root for `/// @inject`
//// functions. The Session type is inferred from the first inject
//// function found, and all inject functions in a namespace must share
//// the same Session type. Place this module wherever you like. By
//// convention we keep it at the top of the server tree alongside the
//// other infrastructure files.

import server/session.{type Session}

/// @inject
///
/// Pulls the per-connection client_id out of the session. Any RPC that
/// declares `client_id client_id: String` as its first labelled
/// parameter will receive this value automatically.
pub fn client_id(session: Session) -> String {
  session.client_id
}
