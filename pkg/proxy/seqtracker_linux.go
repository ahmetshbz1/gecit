package proxy

import "net"

// Linux uses eBPF sock_ops for seq/ack extraction, not pcap.
// This stub exists so the package compiles on Linux.

type SeqTracker struct{}

func SetSeqTracker(_ *SeqTracker) {}

func GetSeqAck(_ net.Conn) (seq, ack uint32) { return 1, 1 }

func (st *SeqTracker) Stop() {}
