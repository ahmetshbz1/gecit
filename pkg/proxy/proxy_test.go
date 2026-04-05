package proxy

import (
	"net"
	"testing"
	"time"
)

func TestPipe_BothSidesClose(t *testing.T) {
	a, b := net.Pipe()
	c, d := net.Pipe()

	done := make(chan struct{})
	go func() {
		pipe(a, c)
		close(done)
	}()

	// Write from b → should arrive at d.
	msg := []byte("hello")
	go func() {
		b.Write(msg)
		b.Close()
	}()

	buf := make([]byte, 64)
	n, _ := d.Read(buf)
	if string(buf[:n]) != "hello" {
		t.Fatalf("expected %q, got %q", "hello", string(buf[:n]))
	}
	d.Close()

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("pipe did not return after both sides closed")
	}
}

func TestPipe_OneSideClosesUnblocksOther(t *testing.T) {
	a, b := net.Pipe()
	c, d := net.Pipe()

	done := make(chan struct{})
	go func() {
		pipe(a, c)
		close(done)
	}()

	// Close only one external side — pipe must still return.
	b.Close()

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("pipe hung when one side closed — missing half-close handling")
	}

	d.Close()
}

func TestPipe_HangingWriterUnblocks(t *testing.T) {
	// Simulate a connection where the remote never closes (hangs).
	// The local side closes — pipe must return, not hang forever.
	a, b := net.Pipe()
	c, d := net.Pipe()

	done := make(chan struct{})
	go func() {
		pipe(a, c)
		close(done)
	}()

	// Close client side immediately.
	b.Close()
	// d (server side) is intentionally left open — simulates a hanging server.

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("pipe hung with a hanging remote — deadline expiry should have unblocked it")
	}

	d.Close()
}

func TestPipe_BidirectionalData(t *testing.T) {
	a, b := net.Pipe()
	c, d := net.Pipe()

	done := make(chan struct{})
	go func() {
		pipe(a, c)
		close(done)
	}()

	// b → a → c → d (forward direction).
	go func() {
		b.Write([]byte("request"))
		// Read the response before closing.
		buf := make([]byte, 64)
		n, _ := b.Read(buf)
		if string(buf[:n]) != "response" {
			t.Errorf("client expected %q, got %q", "response", string(buf[:n]))
		}
		b.Close()
	}()

	// d reads the forwarded data and responds.
	buf := make([]byte, 64)
	n, _ := d.Read(buf)
	if string(buf[:n]) != "request" {
		t.Fatalf("server expected %q, got %q", "request", string(buf[:n]))
	}
	d.Write([]byte("response"))
	d.Close()

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("pipe did not return after bidirectional exchange")
	}
}
