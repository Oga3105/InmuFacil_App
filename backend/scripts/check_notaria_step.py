"""
Diagnostic: check (and optionally repair) the NOTARIA_APPOINTMENT step for an offer.

Usage:
    python -m backend.scripts.check_notaria_step --offer-id 2
    python -m backend.scripts.check_notaria_step --offer-id 2 --force-complete
"""
import argparse
import sys

from backend.src.config.database import SessionLocal
from backend.src.models.timeline import TransactionStep, StepStatus


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--offer-id", type=int, required=True)
    parser.add_argument(
        "--force-complete",
        action="store_true",
        help="Force step.status = COMPLETED (use only when both parties have confirmed in real life)",
    )
    args = parser.parse_args()

    db = SessionLocal()
    try:
        step = (
            db.query(TransactionStep)
            .filter(
                TransactionStep.offer_id == args.offer_id,
                TransactionStep.step_key == "NOTARIA_APPOINTMENT",
            )
            .first()
        )

        if step is None:
            print(f"[ERROR] No NOTARIA_APPOINTMENT step found for offer {args.offer_id}")
            print("  -> The step is created the first time the buyer proposes a date.")
            sys.exit(1)

        print(f"Offer:              {args.offer_id}")
        print(f"step.id:            {step.id}")
        print(f"step.status:        {step.status}")
        print(f"buyer_confirmed_at: {step.buyer_confirmed_at}")
        print(f"seller_confirmed_at:{step.seller_confirmed_at}")
        meta = step.metadata_json or {}
        print(f"metadata.appointment_status: {meta.get('appointment_status')}")

        both_confirmed = (
            step.buyer_confirmed_at is not None
            and step.seller_confirmed_at is not None
        )
        print()
        if step.status == StepStatus.COMPLETED:
            print("[OK] Step is COMPLETED — post-venta gate should pass.")
        elif both_confirmed:
            print("[WARN] Both parties confirmed but step.status is not COMPLETED.")
            print("  -> The new gate code auto-repairs this on next request.")
            print("  -> Or run with --force-complete to fix it now.")
        else:
            print("[BLOCKED] Not both parties have confirmed yet.")
            print(f"  buyer_confirmed_at:  {'SET' if step.buyer_confirmed_at else 'MISSING'}")
            print(f"  seller_confirmed_at: {'SET' if step.seller_confirmed_at else 'MISSING'}")

        if args.force_complete:
            step.status = StepStatus.COMPLETED
            from sqlalchemy.orm.attributes import flag_modified
            meta["appointment_status"] = "completed"
            step.metadata_json = meta
            flag_modified(step, "metadata_json")
            db.commit()
            print()
            print("[FIXED] step.status forced to COMPLETED.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
