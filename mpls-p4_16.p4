#include <core.p4>
#define V1MODEL_VERSION 20200408
#include <v1model.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header mpls_t {
    bit<20> label;
    bit<3>  tc;
    bit<1>  bos;
    bit<8>  ttl;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

struct metadata {
}

struct headers {
    @name(".ethernet")
    ethernet_t ethernet;
    @name(".ipv4")
    ipv4_t     ipv4;
    @name(".mpls")
    mpls_t     mpls;
    @name(".udp")
    udp_t      udp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x8847: parse_mpls;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w0x11: parse_udp;
            default: accept;
        }
    }
    @name(".parse_mpls") state parse_mpls {
        packet.extract(hdr.mpls);
        transition parse_ipv4;
    }
    @name(".parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".push_mpls") action push_mpls(bit<20> label) {
        hdr.mpls.setValid();
        hdr.mpls.label = label;
        hdr.mpls.tc = 3w7;
        hdr.mpls.bos = 1w0x1;
        hdr.mpls.ttl = 8w32;
        hdr.ethernet.etherType = 16w0x8847;
    }
    @name("._drop") action _drop() {
        mark_to_drop(standard_metadata);
    }
    @name(".forward") action forward(bit<9> intf) {
        standard_metadata.egress_spec = intf;
    }
    @name(".pop_mpls") action pop_mpls() {
        hdr.mpls.setInvalid();
        hdr.ethernet.etherType = 16w0x800;
    }
    @name(".swap_mpls") action swap_mpls(bit<20> label) {
        hdr.mpls.label = label;
        hdr.mpls.ttl = hdr.mpls.ttl - 8w1;
    }
    @name(".rewrite_macs") action rewrite_macs(bit<48> srcMac, bit<48> dstMac) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = dstMac;
    }
    @name(".fec_table") table fec_table {
        actions = {
            push_mpls;
            _drop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 1024;
    }
    @name(".iplookup_table") table iplookup_table {
        actions = {
            forward;
            _drop;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 1024;
    }
    @name(".mpls_table") table mpls_table {
        actions = {
            pop_mpls;
            swap_mpls;
            _drop;
        }
        key = {
            standard_metadata.ingress_port: exact;
            hdr.mpls.label                : exact;
        }
        size = 1024;
    }
    @name(".mplslookup_table") table mplslookup_table {
        actions = {
            forward;
            _drop;
        }
        key = {
            hdr.mpls.label: exact;
        }
        size = 1024;
    }
    @name(".switching_table") table switching_table {
        actions = {
            rewrite_macs;
            _drop;
        }
        key = {
            standard_metadata.egress_spec: exact;
        }
        size = 1024;
    }
    apply {
        fec_table.apply();
        mpls_table.apply();
        mplslookup_table.apply();
        if (standard_metadata.egress_spec == 9w0) {
            iplookup_table.apply();
        }
        switching_table.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.mpls);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
