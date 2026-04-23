// FFI for libero/remote_data.gleam - JavaScript target only.
//
// MsgFromServer variants compile to Gleam CustomType subclasses where
// the single payload field is stored at numeric index 0 (i.e. `instance[0]`).
// This matches the compiled output: `constructor($0) { this[0] = $0; }`.
//
// For 0-arity variants (no fields), the wrapper itself IS the value;
// return undefined (Gleam Nil) as an empty acknowledgment.

export function peelMsgWrapper(wrapper) {
  if (wrapper === null || wrapper === undefined) return undefined;
  // Numeric index 0 is the first field of any Gleam custom type variant
  // with fields. If the variant has no fields, wrapper[0] is undefined,
  // which is Gleam Nil - correct for 0-arity acknowledgment variants.
  //
  // DESIGN NOTE: This accepts any object shape by design. The typed
  // decoder layer (rpc_decoders_ffi.mjs) guarantees the correct
  // constructor shape before this is called — validation here would
  // be redundant. See scanner.validate_msg_from_server_fields for
  // the build-time enforcement.
  return wrapper[0];
}
