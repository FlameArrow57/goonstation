/**
 * @file
 * @copyright 2025
 * @author FlameArrow57 (https://github.com/FlameArrow57)
 * @license ISC
 */
import type { BooleanLike } from 'common/react';
import React from 'react';
import {
  Button,
  Collapsible,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface GPSData {
  src_x: number;
  src_y: number;
  track_x: number;
  track_y: number;
  tracking: BooleanLike;
  trackable: BooleanLike;
  src_name: string;
  distress: BooleanLike;
  gps_info: GPSTrackableData[];
  imp_info: GPSTrackableData[];
  warp_info: GPSTrackableData[];
}

interface GPSTrackableData {
  name: string;
  obj_ref: string;
  x: number;
  y: number;
  z_info: string;
  distress: BooleanLike | null;
}

const gpsTooltip =
  'Each GPS is coined with a unique four digit number followed by a four letter identifier.';

export const GPS = () => {
  const { act, data } = useBackend<GPSData>();
  const {
    src_x,
    src_y,
    track_x,
    track_y,
    tracking,
    trackable,
    src_name,
    distress,
    gps_info,
    imp_info,
    warp_info,
  } = data;

  return (
    <Window title="GPS" width={460} height={610} theme="ntos">
      <Window.Content>
        <Section title={`GPS Device ${src_name}`}>
          <Stack>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Coordinates">
                  {src_x}, {src_y}
                </LabeledList.Item>
                <LabeledList.Item label="Identifier">
                  <Button
                    onClick={() => act('change_identifier')}
                    tooltip={gpsTooltip}
                  >
                    {src_name.slice(5, src_name.length)}
                  </Button>
                </LabeledList.Item>
                <LabeledList.Item label="Coords">
                  x:{' '}
                  <NumberInput
                    value={track_x}
                    width="3"
                    minValue={1}
                    maxValue={300}
                    step={1}
                    onChange={(x_val: number) => act('set_x', { x: x_val })}
                  />
                  y:{' '}
                  <NumberInput
                    value={track_y}
                    width="3"
                    minValue={1}
                    maxValue={300}
                    step={1}
                    onChange={(y_val: number) => act('set_y', { y: y_val })}
                  />
                  <Button
                    mt={0.5}
                    onClick={() =>
                      act('track_coords', { x: track_x, y: track_y })
                    }
                  >
                    Track
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Trackable">
                  <Button.Checkbox
                    onClick={() => act('toggle_trackable')}
                    selected={trackable}
                    checked={trackable}
                  >
                    {trackable ? 'Yes' : 'No'}
                  </Button.Checkbox>
                </LabeledList.Item>
                <LabeledList.Item label="Send distress">
                  <Button.Checkbox
                    onClick={() => act('toggle_distress')}
                    selected={distress}
                    checked={distress}
                  >
                    {distress ? 'Yes' : 'No'}
                  </Button.Checkbox>
                </LabeledList.Item>
                <LabeledList.Item label="Tracking">
                  <Button onClick={() => act('track_gps')}>
                    {tracking || 'None'}
                  </Button>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
          </Stack>
        </Section>
        <Section title="Tracking">
          <Collapsible title="GPS Devices">
            <TrackableList gps_info={gps_info} />
          </Collapsible>
          <Collapsible title="Implants">
            <TrackableList gps_info={imp_info} />
          </Collapsible>
          <Collapsible title="Warp Beacons">
            <TrackableList gps_info={warp_info} />
          </Collapsible>
        </Section>
      </Window.Content>
    </Window>
  );
};

interface TrackableListProps {
  gps_info: GPSTrackableData[];
}

let distress_red = false;
const TrackableList = (props: TrackableListProps) => {
  const { act } = useBackend();
  const { gps_info } = props;

  distress_red = !distress_red;

  return gps_info.length ? (
    <Stack vertical>
      {gps_info.map((item) => (
        <React.Fragment key={item.obj_ref}>
          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Stack
                  vertical
                  textColor={item.distress && distress_red ? 'bad' : undefined}
                >
                  <Stack.Item>
                    <strong>{item.name}</strong>
                    {!!item.distress && ' [Distress!]'}
                  </Stack.Item>
                  <Stack.Item>
                    <em>{`Located at (${item.x}), (${item.y}) | ${item.z_info}`}</em>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item align="center">
                <Button
                  onClick={() => act('track_gps', { gps_ref: item.obj_ref })}
                >
                  Track
                </Button>
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Divider />
        </React.Fragment>
      ))}
    </Stack>
  ) : (
    'None found'
  );
};
