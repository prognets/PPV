#include <core.p4>
#include <v1model.p4>

/*
 * Standard ethernet header
 */
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

/*
 * This is a custom protocol header for the PPV. We'll use ethertype 0x1234
 */
const bit<16> P4PPV_ETYPE = 0x1234;

header p4ppv_t {
    bit<32>  ppv;
    bit<32>  zero;
    bit<32>  one;
    bit<32>  two;
    bit<32>  three;
}

typedef bit<48> time_t;

/*
 * All headers, used in the program needs to be assembed into a single struct.
 * We only need to declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */
struct headers {
    ethernet_t   ethernet;
    p4ppv_t     p4ppv;
}

/*
 * All metadata, globally used in the program, also  needs to be assembed
 * into a single struct. As in the case of the headers, we only need to
 * declare the type, but there is no need to instantiate it,
 * because it is done "by the architecture", i.e. outside of P4 functions
 */

struct metadata {
    /* In our case it is empty */
}


/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            P4PPV_ETYPE : parse_p4ppv;
            default      : accept;
        }
    }

    state parse_p4ppv {
        packet.extract(hdr.p4ppv);
        transition accept;
    }
}

/*************************************************************************
 ************   C H E C K S U M    V E R I F I C A T I O N   *************
 *************************************************************************/
control MyVerifyChecksum(inout headers hdr,
                         inout metadata meta) {
    apply { }
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {



    register<bit<32>>(8) byte_cnt_reg;
    register<time_t>(1) last_time_reg;
    register<bit<32>>(1) offset_reg;

    action send_back() {
        bit<48> tmp;

        bit<32> offset;
        offset_reg.read(offset, 0);

        byte_cnt_reg.read(hdr.p4ppv.zero, 0 + offset);
        byte_cnt_reg.read(hdr.p4ppv.one, 1 + offset);
        byte_cnt_reg.read(hdr.p4ppv.two, 2 + offset);
        byte_cnt_reg.read(hdr.p4ppv.three, 3 + offset);

        /* Swap the MAC addresses */
        tmp = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
        hdr.ethernet.srcAddr = tmp;
        /* Send the packet back to the port it came from */
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }

    action operation_drop() {
        mark_to_drop(standard_metadata);
    }


    apply {

        if (hdr.p4ppv.isValid()) {
            time_t last_time;
            bit<32> byte_cnt;
            bit<32> offset;
            last_time_reg.read(last_time, 0);
            if(standard_metadata.ingress_global_timestamp >= last_time  + 3000000){
                last_time_reg.write(0, standard_metadata.ingress_global_timestamp);
                offset_reg.read(offset,0);
                if(offset == 4){
                    offset_reg.write(0,0);
                }
                else{
                    offset_reg.write(0,4);
                }
                offset_reg.read(offset,0);
                byte_cnt_reg.write(0 + offset, 0);
                byte_cnt_reg.write(1 + offset, 0);
                byte_cnt_reg.write(2 + offset, 0);
                byte_cnt_reg.write(3 + offset, 0);
            }
            offset_reg.read(offset,0);
            byte_cnt_reg.read(byte_cnt, hdr.p4ppv.ppv + offset);
            byte_cnt_reg.write(hdr.p4ppv.ppv + offset, byte_cnt + standard_metadata.packet_length);
            send_back();
        } else {
            operation_drop();
        }

    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

/*************************************************************************
 *************   C H E C K S U M    C O M P U T A T I O N   **************
 *************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

/*************************************************************************
 ***********************  D E P A R S E R  *******************************
 *************************************************************************/
control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.p4ppv);
    }
}

/*************************************************************************
 ***********************  S W I T T C H **********************************
 *************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
