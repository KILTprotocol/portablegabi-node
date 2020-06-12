//! The Substrate node template runtime reexported for WebAssembly compile.

#![cfg_attr(not(feature = "std"), no_std)]

pub use portablegabi_node_runtime::*;
