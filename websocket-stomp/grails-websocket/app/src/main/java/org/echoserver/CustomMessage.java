package org.echoserver;

public class CustomMessage {
    private final String content;

    public CustomMessage(String content) {
        this.content = content;
    }

    public String getContent() {
        return content;
    }

    @Override
    public String toString() {
        return content;
    }
}