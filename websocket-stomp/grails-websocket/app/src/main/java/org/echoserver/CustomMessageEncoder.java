package org.echoserver;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.MessageToByteEncoder;

public class CustomMessageEncoder extends MessageToByteEncoder<CustomMessage> {

    @Override
    protected void encode(ChannelHandlerContext ctx, CustomMessage msg, ByteBuf out) throws Exception {
        out.writeBytes(msg.getContent().getBytes());
    }
}