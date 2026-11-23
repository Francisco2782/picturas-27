const amqp = require('amqplib/callback_api');

const rabbit_host = process.env.RABBITMQ_HOST;
const rabbit_port = process.env.RABBITMQ_PORT;
const rabbit_username = process.env.RABBITMQ_USER;
const rabbit_password = process.env.RABBITMQ_PASS;
const exchange = "picturas";

const rabbit_mq_sv = `amqp://${rabbit_username}:${rabbit_password}@${rabbit_host}:${rabbit_port}`;
const { settleDelivery } = require("./rabbitDelivery");

function send_rabbit_msg(msg, queue) {
    amqp.connect(rabbit_mq_sv, (err_sv, connection) => {
        if (err_sv) throw err_sv;
        
        connection.createChannel( (err_conn, channel) => {
            if (err_conn) throw err_conn;
            
            channel.assertExchange(exchange, 'direct', {
                durable: true
            });

            channel.publish(exchange, queue, Buffer.from(JSON.stringify(msg)));
        });
        
        setTimeout(() => {
            connection.close();
        }, 500);
    });
    
}

function read_rabbit_msg(queue, callback) {
    const retry = (reason) => {
        console.error(`[rabbit] ${reason}; reconnecting in 3s`);
        setTimeout(() => read_rabbit_msg(queue, callback), 3000);
    };
    amqp.connect(rabbit_mq_sv, (err_sv, connection) => {
        if (err_sv) return retry(err_sv.message);

        let reconnecting = false;
        const reconnect = (reason, closeConnection = false) => {
            if (reconnecting) return;
            reconnecting = true;
            if (closeConnection) connection.close(() => {});
            retry(reason);
        };
        connection.on('error', (error) => reconnect(error.message));
        connection.once('close', () => reconnect('connection closed'));

        connection.createChannel((err_conn, channel) => {
            if (err_conn) return reconnect(err_conn.message, true);
            channel.on('error', (error) => reconnect(error.message, true));
            channel.once('close', () => reconnect('channel closed', true));

            channel.assertQueue(queue, { durable: true }, (err_queue, q) => {
                if (err_queue) return reconnect(err_queue.message, true);

                channel.consume(q.queue, (msg) => {
                    if (msg === null) return reconnect(`consumer for ${queue} cancelled`, true);
                    settleDelivery(
                        msg,
                        callback,
                        (delivery) => { if (!reconnecting) channel.ack(delivery); },
                        (delivery) => { if (!reconnecting) channel.nack(delivery, false, true); },
                    );
                }, {
                    noAck: false
                }, (error) => {
                    if (error) reconnect(error.message, true);
                });
            });
        });
    });
}

module.exports = { send_rabbit_msg, read_rabbit_msg };
