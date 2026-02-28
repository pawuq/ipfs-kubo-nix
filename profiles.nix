{ infuse, ... }:
# https://github.com/ipfs/kubo/blob/v0.40.1/config/import.go
let
  HAMTSizeEstimationBlock = "block";
  DAGLayoutBalanced = "balanced";
in
# https://github.com/ipfs/kubo/blob/v0.40.1/config/profile.go#L27
let
  # defaultServerFilters has is a list of IPv4 and IPv6 prefixes that are private, local only, or unrouteable.
  # according to https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
  # and https://www.iana.org/assignments/iana-ipv6-special-registry/iana-ipv6-special-registry.xhtml
  defaultServerFilters = [
    "/ip4/10.0.0.0/ipcidr/8"
    "/ip4/100.64.0.0/ipcidr/10"
    "/ip4/169.254.0.0/ipcidr/16"
    "/ip4/172.16.0.0/ipcidr/12"
    "/ip4/192.0.0.0/ipcidr/24"
    "/ip4/192.0.2.0/ipcidr/24"
    "/ip4/192.168.0.0/ipcidr/16"
    "/ip4/198.18.0.0/ipcidr/15"
    "/ip4/198.51.100.0/ipcidr/24"
    "/ip4/203.0.113.0/ipcidr/24"
    "/ip4/240.0.0.0/ipcidr/4"
    "/ip6/100::/ipcidr/64"
    "/ip6/2001:2::/ipcidr/48"
    "/ip6/2001:db8::/ipcidr/32"
    "/ip6/fc00::/ipcidr/7"
    "/ip6/fe80::/ipcidr/10"
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
