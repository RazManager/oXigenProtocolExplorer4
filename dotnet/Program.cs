using System;
using System.Collections.Concurrent;
using System.IO.Ports;
using System.Linq;


internal class Program
{
    private string serialPortName = null!;
    private short txDelay = 500;
    private short txTimeout = 2000;
    private short controllerTimeout = 30;

    private short _txDelay;
    private short _txTimeout;
    private short _controllerTimeout;
    private static SerialPort _serialPort;

    private static ConcurrentDictionary<byte, DateTime?> _refreshRates = new();
    private static ConcurrentDictionary<byte, int?> _laps = new();
    private System.Threading.Timer? txTimeoutTimer;

    static void Main(string[] args)
    {
        var serialPortNames = SerialPort.GetPortNames().OrderBy(x => x);
        if (!serialPortNames.Any())
        {
            Console.WriteLine("There are no serial ports.");
            return;
        }
        foreach (var serialPort in serialPortNames.Select((x, i) => new { index = i, serialPortName = x }))
        {
            Console.WriteLine($" {serialPort.index + 1}. {serialPort.serialPortName}");
        }

        Console.Write("Please select a serial port: ");
        var selectedSerialPortIndexString = Console.ReadLine();
        if (string.IsNullOrWhiteSpace(selectedSerialPortIndexString))
        {
            return;
        }
        if (!byte.TryParse(selectedSerialPortIndexString, out var selectedSerialPortIndex))
        {
            return;
        }
        if (selectedSerialPortIndex < 1 || selectedSerialPortIndex > serialPortNames.Count())
        {
            return;
        }
        var serialPortName = serialPortNames.ElementAt(selectedSerialPortIndex - 1);

        Console.WriteLine($"Opening {serialPortName}...");
        _serialPort = new SerialPort(serialPortName);
        _serialPort.BaudRate = 9600;
        _serialPort.DataBits = 8;
        _serialPort.Parity = Parity.None;
        _serialPort.StopBits = StopBits.One;
        _serialPort.ReadBufferSize = 65536;
        _serialPort.ReadTimeout = 300;
        _serialPort.ReceivedBytesThreshold = 1;
        _serialPort.Handshake = Handshake.XOnXOff;
        _serialPort.DtrEnable = true;
        _serialPort.RtsEnable = false;
        _serialPort.DataReceived += _serialPort_Rx;
        _serialPort.ErrorReceived += _serialPort_ErrorReceived;
        _serialPort.Open();
        Console.WriteLine($"{_serialPort.PortName} opened.");

        var buffer = new byte[] { 6, 6, 6, 6, 0, 0, 0 };
        _serialPort.Write(buffer, 0, buffer.Length);

        Console.ReadLine();

        _serialPort.Close();
    }


    private static void _serialPort_Rx(object sender, SerialDataReceivedEventArgs e)
    {
        try
        {
            var now = DateTime.Now;
            var buffer = new byte[_serialPort.ReadBufferSize];
            var bytesRead = _serialPort.Read(buffer, 0, _serialPort.BytesToRead);
            //Console.WriteLine($"{bytesRead} bytes received.");

            if (bytesRead == 5 || bytesRead == 18)
            {
                buffer = new byte[] { 15, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
                _serialPort.Write(buffer, 0, buffer.Length);
            }
            else if (bytesRead > 0 && bytesRead % 13 == 0)
            {
                var offset = 0;
                do
                {
                    var id = buffer[1 + offset];
                    var lap = buffer[6 + offset] * 256 + buffer[5 + offset];

                    _refreshRates.TryGetValue(id, out var dt);
                    if (!dt.HasValue)
                    {
                        Console.WriteLine($"Id={id}");
                    }
                    else
                    {
                        var refreshRate = Math.Round((now - dt.Value).TotalMilliseconds, 0);
                        Console.WriteLine($"Id={id}, Refresh rate={refreshRate}ms{(refreshRate > 310 ? " (more than 300)" : "")}");
                    }
                    _refreshRates.AddOrUpdate(id, now, (_, _) => now);

                    _laps.TryGetValue(id, out var prevLap);
                    if (!prevLap.HasValue)
                    {
                        Console.WriteLine($"Id={id} Lap={lap}");
                    }
                    else
                    {
                        if (lap > prevLap.Value)
                        {
                            if (lap - prevLap.Value > 1)
                            {
                                Console.WriteLine("*******************************************************");
                                //Console.Beep(400, 1000);
                            }
                            Console.WriteLine($"Id={id} Lap={lap}");
                            Console.Beep();
                        }
                    }
                    _laps.AddOrUpdate(id, lap, (_, _) => lap);

                    offset += 13;
                } while (offset < bytesRead - 1);
            }
        }
        catch (Exception exception)
        {
            Console.WriteLine(exception.Message);
        }
    }


    private static void _serialPort_ErrorReceived(object sender, SerialErrorReceivedEventArgs e)
    {
        Console.WriteLine(e.EventType);
    }
}