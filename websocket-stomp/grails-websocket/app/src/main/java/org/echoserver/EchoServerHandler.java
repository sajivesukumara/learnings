package org.echoserver;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandler.Sharable;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.util.ReferenceCountUtil;

/**
 * Handler implementation for the echo server.
 */
@Sharable
public class EchoServerHandler extends ChannelInboundHandlerAdapter {

    public void ReceivedMessage(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        try {
            while (in.isReadable()) { // (1)
                System.out.print((char) in.readByte());
                // ctx.write(in.readByte());
                System.out.flush();
            }
        } finally {
            ReferenceCountUtil.release(msg); // (2)
        }
    }

    public void ReceivedAndReploy(ChannelHandlerContext ctx, Object msg) {
        if (msg instanceof ByteBuf) {
            ByteBuf in = (ByteBuf) msg;
            try {
                StringBuilder content = new StringBuilder();
                while (in.isReadable()) {
                    content.append((char) in.readByte());
                    System.out.print("["+content.toString()+"]");
                    System.out.flush();
                }
                CustomMessage customMsg = new CustomMessage(" => " + content.toString());
                ctx.writeAndFlush(customMsg);
            } finally {
                in.release();
            }
        } else {
            System.out.println("Received message of unknown type: " + msg.getClass());
        }
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ReceivedAndReploy(ctx, msg);
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) {
        ctx.flush();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        // Close the connection when an exception is raised.
        cause.printStackTrace();
        ctx.close();
    }
}