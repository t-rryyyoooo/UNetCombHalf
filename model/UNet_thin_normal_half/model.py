import torch
from torch import nn
from model_part import CreateUpConvBlock
from model_thin_UNet import BuildThinUNet

class CombNet(nn.Module):
    def __init__(self, in_channel_1=64, in_channel_thin=1, out_channel_thin=64, num_class=14):
        super(CombNet, self).__init__()

        self.thin_UNet = BuildThinUNet(
                in_channel = in_channel_thin,
                out_channel = out_channel_thin
                )

        self.expand_1 = CreateUpConvBlock(out_channel_thin, in_channel_1, in_channel_1, in_channel_1)

        self.segmentation = nn.Conv3d(in_channel_1, num_class, (1, 1, 1), stride=1, dilation=1, padding=(0, 0, 0))

        self.softmax = nn.Softmax(dim=1)

    def forward(self, input_1, thin_input):
        x = self.thin_UNet(thin_input)
        x = self.expand_1(x, input_1)
        x = self.segmentation(x)
        x = self.softmax(x)

        return x


if __name__ == "__main__":
    in_channel_1 = 32
    in_channel_thin = 1
    out_channel_thin = 32

    model = CombNet(
            in_channel_1=in_channel_1, 
            in_channel_thin=in_channel_thin, 
            out_channel_thin=out_channel_thin,
            num_class=14
            )

    input_1_shape = [2, in_channel_1, 512, 512, 8*4]
    input_thin_shape = [2, in_channel_thin, 256, 256, 16]

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    model.to(device)
    #from torchsummary import summary
    #summary(model, [input_1_shape, input_thin_shape])

    input_1_dummy = torch.rand(input_1_shape).to(device)
    input_thin_dummy = torch.rand(input_thin_shape).to(device)

    print("Device:", device)
    print("Input:", input_1_dummy.shape, input_thin_dummy.shape)

    output = model(input_1_dummy, input_thin_dummy)
    print("Output :", output.size())

