import argparse
import json
import logging

from faker import Faker

# from pytz import utc as pytz_utc
from datetime import timezone

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

log = logging.getLogger(__name__)
log.info("Starting Generate Mock User Orders Script...")

fake = Faker()


def get_arguments() -> tuple[int]:
    """Parse command line arguments - Currently only service name"""
    parser = argparse.ArgumentParser(description="Generate Mock User Orders")
    parser.add_argument(
        "--number-of-events",
        help="Number of events to generate. Default is 1",
        default="1",
    )
    args = parser.parse_args()
    return int(args.number_of_events)


def generate_mock_vinyl_albums(number_of_vinyl: int) -> list[dict]:
    """Generate mock vinyl albums"""
    mock_vinyl_albums = []
    for i in range(number_of_vinyl):
        mock_vinyl = {
            "vinyl_album_id": fake.uuid4(),
            "vinyl_album_name": fake.sentence(
                nb_words=3, variable_nb_words=True, ext_word_list=None
            ),
            "vinyl_album_artist": fake.name(),
            "vinyl_album_price": fake.pydecimal(
                left_digits=2, right_digits=2, positive=True
            ),
        }
        mock_vinyl_albums.append(mock_vinyl)
    return mock_vinyl_albums


def get_vinyl_record_orders(vinyl_records: list[dict]) -> list[dict]:
    number_of_vinyl_records = fake.random_int(min=1, max=5)
    log.info(f"Len of vinyl_records: {len(vinyl_records)}")
    return fake.random_elements(elements=vinyl_records, length=number_of_vinyl_records)


def generate_mock_orders(
    number_of_events: int, vinyl_records: list[dict]
) -> list[dict]:
    """Generate mock orders"""
    mock_orders = []
    for i in range(number_of_events):
        mock_timestamp = fake.date_time_between(
            start_date="-1y", end_date="now", tzinfo=timezone.utc
        )
        mock_order = {
            "order_id": fake.uuid4(),
            "id": fake.uuid4(),
            "amount": fake.random_int(min=1, max=1000),
            "order_timestamp": mock_timestamp.timestamp(),
            "timestamp": mock_timestamp,
            "currency": "USD",
            "items": get_vinyl_record_orders(vinyl_records),
        }
        mock_orders.append(mock_order)
    return mock_orders


def main():
    number_of_events = get_arguments()

    confirmation = input(
        f"Please confirm you want to generate {number_of_events} mock orders (y/n): "
    )
    if confirmation != "y":
        log.info("Confirmation was not 'y' - Exiting...")
        exit(0)

    number_of_vinyl = 10
    log.info(f"Generating {number_of_vinyl} mock vinyl albums...")
    mock_vinyl_albums = generate_mock_vinyl_albums(number_of_vinyl)
    mock_orders = generate_mock_orders(number_of_events, mock_vinyl_albums)
    log.info(mock_orders)

    # write mock orders to json file
    with open("mock_user_orders.json", "w") as f:
        json.dump(mock_orders, f, indent=4, sort_keys=True, default=str)


if __name__ == "__main__":
    main()
