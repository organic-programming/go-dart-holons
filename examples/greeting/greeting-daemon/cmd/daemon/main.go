// greeting-daemon — a Godart example: greets users in 56 languages.
package main

import (
	"fmt"
	"os"

	pb "github.com/organic-programming/go-dart-holons/examples/greeting-daemon/gen/go/greeting/v1"
	"github.com/organic-programming/go-dart-holons/examples/greeting-daemon/internal/server"
	"github.com/organic-programming/go-holons/pkg/serve"

	"google.golang.org/grpc"
)

func main() {
	if len(os.Args) < 2 {
		usage()
	}

	switch os.Args[1] {
	case "serve":
		listenURI := serve.ParseFlags(os.Args[2:])
		if err := serve.Run(listenURI, func(gs *grpc.Server) {
			pb.RegisterGreetingServiceServer(gs, &server.Server{})
		}); err != nil {
			fmt.Fprintf(os.Stderr, "serve error: %v\n", err)
			os.Exit(1)
		}
	case "version":
		fmt.Println("greeting-daemon v0.1.0")
	default:
		usage()
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, "usage: daemon <serve|version> [flags]")
	fmt.Fprintln(os.Stderr, "  serve   Start the gRPC server (--listen <uri>)")
	fmt.Fprintln(os.Stderr, "  version Print version and exit")
	os.Exit(1)
}
