async function settleDelivery(message, callback, ack, nack) {
  try {
    await callback(message);
    ack(message);
    return true;
  } catch (error) {
    nack(message, error);
    return false;
  }
}

module.exports = { settleDelivery };
