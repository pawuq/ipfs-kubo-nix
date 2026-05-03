{ infuse, ... }:
# https://github.com/ipfs/kubo/blob/v0.40.1/config/import.go
let
  HAMTSizeEstimationBlock = "block";
  DAGLayoutBalanced = "balanced";
in
let
  # https://github.com/ipfs/kubo/blob/v0.41.0/config/profile.go#L39

  # defaultServerFilters lists IPv4 and IPv6 prefixes that are private,
  # local-only, or otherwise not "Globally Reachable" per the IANA
  # Special-Purpose Address Registries (RFC 6890):
  #
  #     https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
  #     https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml
  #
  # The `server` profile appends this list to both `Addresses.NoAnnounce`
  # (strip from self-announce / identify / DHT self-record) and
  # `Swarm.AddrFilters` (refuse libp2p dial/accept involving these ranges).
  # See docs/config.md under "`server` profile" for the rendered table with
  # per-entry RFC references and guidance on optional entries (for example
  # loopback or IPv6 outside `2000::/3`) that operators may add manually.
  #
  # Keep this list stable; changes here affect every `server`-profile user.
  defaultServerFilters = [
    "/ip4/10.0.0.0/ipcidr/8"      # RFC 1918: private-use
    "/ip4/100.64.0.0/ipcidr/10"   # RFC 6598: shared address space (CGNAT)
    "/ip4/127.0.0.0/ipcidr/8"     # RFC 1122: IPv4 loopback
    "/ip4/169.254.0.0/ipcidr/16"  # RFC 3927: link-local
    "/ip4/172.16.0.0/ipcidr/12"   # RFC 1918: private-use
    "/ip4/192.0.0.0/ipcidr/24"    # RFC 6890: IETF protocol assignments
    "/ip4/192.0.2.0/ipcidr/24"    # RFC 5737: TEST-NET-1 (documentation)
    "/ip4/192.168.0.0/ipcidr/16"  # RFC 1918: private-use
    "/ip4/198.18.0.0/ipcidr/15"   # RFC 2544: benchmarking
    "/ip4/198.51.100.0/ipcidr/24" # RFC 5737: TEST-NET-2 (documentation)
    "/ip4/203.0.113.0/ipcidr/24"  # RFC 5737: TEST-NET-3 (documentation)
    "/ip4/240.0.0.0/ipcidr/4"     # RFC 1112: reserved (covers broadcast 255.255.255.255)
    "/ip6/::/ipcidr/3"            # RFC 4291 §2.4: IANA-reserved 0000::/3 block (unspecified, loopback, IPv4-mapped, NAT64, and unallocated space where 1e::/16 leaks)
    "/ip6/::1/ipcidr/128"         # RFC 4291 §2.4: IPv6 loopback (subset of `::/3` above; kept for documentation)
    "/ip6/100::/ipcidr/64"        # RFC 6666: discard-only (subset of `::/3` above; kept for documentation)
    "/ip6/2001:2::/ipcidr/48"     # RFC 5180: BMWG benchmarking
    "/ip6/2001:db8::/ipcidr/32"   # RFC 3849: documentation
    "/ip6/fc00::/ipcidr/7"        # RFC 4193: unique local addresses (ULA)
    "/ip6/fe80::/ipcidr/10"       # RFC 4291: link-local unicast
  ];
in
{
  # https://github.com/ipfs/kubo/blob/v0.40.1/config/profile.go#L48
  server = {
    description = ''
      Disables local host discovery, recommended when
      running IPFS on machines with public IPv4 addresses.
    '';
    transform =
      final: prev:
      infuse prev {
        "Addresses"."NoAnnounce".__append = defaultServerFilters;
        "Swarm"."AddrFilters" = [
          (x: if x == null then [ ] else x)
          { __append = defaultServerFilters; }
        ];
        "Discovery"."MDNS"."Enabled".__assign = false;
        "Swarm"."DisableNatPortMap".__assign = true;
      };
  };

  # https://github.com/ipfs/kubo/blob/v0.40.1/config/profile.go#L337
  unixfs-v1-2025 = {
    description = ''
      Recommended UnixFS import profile for cross-implementation CID determinism.
      Uses CIDv1, raw leaves, sha2-256, 1 MiB chunks, 1024 links per file node,
      256 HAMT fanout, and block-based size estimation for HAMT threshold.
      See https://github.com/ipfs/specs/pull/499
    '';
    transform =
      final: prev:
      infuse prev {
        "Import" = {
          "CidVersion".__assign = 1;
          "UnixFSRawLeaves".__assign = true;
          "UnixFSChunker".__assign = "size-1048576"; # 1 MiB
          "HashFunction".__assign = "sha2-256";
          "UnixFSFileMaxLinks".__assign = 1024;
          "UnixFSDirectoryMaxLinks".__assign = 0;
          "UnixFSHAMTDirectoryMaxFanout".__assign = 256;
          "UnixFSHAMTDirectorySizeThreshold".__assign = "256KiB";
          "UnixFSHAMTDirectorySizeEstimation".__assign = HAMTSizeEstimationBlock;
          "UnixFSDAGLayout".__assign = DAGLayoutBalanced;
        };
      };
  };
}
