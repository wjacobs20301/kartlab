# Later crash after remote-driving test

The user reports no usable entry/driving interaction. The previous bounded-loop log establishes script execution and input reads, not a playable mounted controller.

At 00:28:45.093 in .work/ryujinx-kart-model-patched-spawn-test.log, PC subsdk9+0x1fd310 is inside strlen; LR+0x1a82c is inside the std::string char-pointer constructor. The stack includes ActorWatcher::calc+0x1334 (module+0x2b374). Address 0xC was invalid. ELF symbols were read from the pinned debug module; new REA function evidence ev_d0f8030cdf7edd73bf02dc962c92620d099d3723c61ed3b7c02e014588a2246c confirms the surrounding watcher function.

The native instruction at0x2b370 calls the std::string constructor immediately after JSON-value setup; this is actor-name JSON logging, not the TextWriter-only branch. The observed invalid source pointer is consistent with a stale actor/name in watcher telemetry. It does not prove which watcher or what invalidated it. Remove display/log telemetry and pause a resolved watcher so the native draw loop does not repeatedly dereference it. This mitigation still needs runtime validation and does not solve script actor lifetime.

Full retained native analysis exported to .work/native/rea-actor-watcher-crash-evidence.json; REA session closed.
