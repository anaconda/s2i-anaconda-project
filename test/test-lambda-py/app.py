import logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def handler(event, context):
    event['Key'] = 'output'
    logger.debug(event)
    return event