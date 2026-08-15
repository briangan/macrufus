import time
import math

def simulate_disk_transfer(total_bytes: int, transfer_speed_bps: int):
    """
    Simulates a long-lasting disk transfer and prints status updates.

    Args:
        total_bytes: The total number of bytes to be transferred.
        transfer_speed_bps: The transfer speed in bits per second (bps).
    """
    start_time = time.time()
    bytes_transferred = 0
    
    print("Starting disk operation simulation...")

    while bytes_transferred < total_bytes:
        # Simulate a small chunk of data being transferred in each iteration
        # We'll simulate a fixed transfer rate for simplicity, or you could introduce randomness.
        # For this example, we'll calculate the time needed to transfer the remaining amount at the given speed.
        
        time_elapsed = time.time() - start_time
        
        # Calculate how much data *should* have been transferred based on time and speed
        # We use a simple linear progression for simulation purposes.
        
        # Determine the next step size to simulate progress
        # Let's assume we transfer 10MB (10 * 1024^2) per second as a base rate for demonstration, 
        # or simply calculate based on time elapsed.
        
        # For a more realistic simulation, let's calculate the actual transferred amount based on time and speed.
        current_transfer = transfer_speed_bps * time_elapsed
        bytes_transferred = min(total_bytes, int(current_transfer))

        # Format the output string
        time_elapsed_s = time_elapsed
        
        # Convert bytes to MB and MiB (using 1024 for MiB)
        mb = bytes_transferred / (1024 * 1024)
        mib = bytes_transferred / (1024 * 1024 * 1024)

        # Calculate transfer rate in KB (since the example shows 'k')
        kb_transferred = bytes_transferred / 1024
        
        # Format the output string as requested: "X bytes (Y MB, Z MiB) transferred T s, R k"
        status_text = (
            f"{bytes_transferred} bytes ({mb:.2f} MB, {mib:.2f} MiB) "
            f"transferred {time_elapsed_s:.3f}s, {kb_transferred:.1f} k"
        )
        
        # Print the status text on the same line using \r
        print(f"\r{status_text}", end="")

        # To prevent an infinite loop if the speed is too slow or calculation stalls, 
        # we ensure progress is made. In a real scenario, this would be driven by I/O operations.
        if bytes_transferred == total_bytes:
            break
        
        # Small sleep to simulate real-world delay and allow output to be visible
        time.sleep(0.1)


if __name__ == "__main__":
    # --- Configuration ---
    # Total size of the disk image/file to transfer (e.g., 109051904 bytes = 100 MiB)
    
    # Transfer speed in bytes per second (Bps). Example: 100 MB/s * 8 bits/byte
    TRANSFER_SPEED_BPS = 800000  # 800 Bps (800 bytes per second)

    TOTAL_SIZE_BYTES = TRANSFER_SPEED_BPS * 180

    print(f"--- Disk Transfer Simulation ---")
    print(f"Total size to transfer: {TOTAL_SIZE_BYTES} bytes")
    print(f"Transfer speed set to: {TRANSFER_SPEED_BPS / (1024*1024*1024):.2f} GB/s\n")

    # Print estimated time to complete the transfer
    estimated_time = TOTAL_SIZE_BYTES / TRANSFER_SPEED_BPS  # in seconds
    print(f"Estimated time to complete transfer: {estimated_time:.2f} seconds\n")

    simulate_disk_transfer(TOTAL_SIZE_BYTES, TRANSFER_SPEED_BPS)