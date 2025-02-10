/**
 * @file
 * @copyright 2025
 * @author FlameArrow57 (https://github.com/FlameArrow57)
 * @license ISC
 */

import {
  Button,
  LabeledList,
  Modal,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface MicrowaveData {
  broken: boolean;
  operating: boolean;
  dirty: boolean;
  eggs: number;
  flour: number;
  monkey_meat: number;
  synth_meat: number;
  donk_pockets: number;
  other_meat: number;
  unusual_item: string;
}

export const Microwave = () => {
  const { act, data } = useBackend<MicrowaveData>();
  const {
    broken,
    operating,
    dirty,
    eggs,
    flour,
    monkey_meat,
    synth_meat,
    donk_pockets,
    other_meat,
    unusual_item,
  } = data;

  return (
    <Window title="Microwave Controls" width={250} height={310}>
      <Window.Content>
        <Section fill>
          <Section title="Contents">
            <LabeledList>
              <LabeledList.Item label="Eggs">{eggs}</LabeledList.Item>
              <LabeledList.Item label="Flour">{flour}</LabeledList.Item>
              <LabeledList.Item label="Monkey Meat">
                {monkey_meat}
              </LabeledList.Item>
              <LabeledList.Item label="Synth-Meat">
                {synth_meat}
              </LabeledList.Item>
              <LabeledList.Item label="Meat Turnovers">
                {donk_pockets}
              </LabeledList.Item>
              <LabeledList.Item label="Other Meat">
                {other_meat}
              </LabeledList.Item>
              {unusual_item && (
                <LabeledList.Item label="???">{unusual_item}</LabeledList.Item>
              )}
            </LabeledList>
            <Stack vertical mt={1}>
              <Stack.Item>
                <Button
                  color="green"
                  onClick={() => act('start_microwave')}
                >
                  Start!
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button onClick={() => act('eject_contents')}>
                  Eject contents
                </Button>
              </Stack.Item>
            </Stack>
          </Section>
        </Section>
        {!!broken && (
          <Modal>
            <Section>
              This microwave is broken! Repair required, with a screwdriver and
              wrench.
            </Section>
          </Modal>
        )}
        {!!dirty && (
          <Modal>
            <Section>
              This microwave is dirty! Please clean before use with a sponge or
              cleaner bottle.
            </Section>
          </Modal>
        )}
        {!!operating && (
          <Modal>
            <Section>Microwaving in progress! Please wait...</Section>
          </Modal>
        )}
      </Window.Content>
    </Window>
  );
};
