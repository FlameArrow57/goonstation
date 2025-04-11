/**
 * @file
 * @copyright 2025
 * @author FlameArrow57
 * @license ISC
 */
import { Image } from 'tgui-core/components';

import { resource } from '../../../goonstation/cdn';
import { AlertContentWindow } from '../types';

export const acw: AlertContentWindow = {
  title: 'Mindeater Basics',
  content: (
    <div className="traitor-tips">
      <h1 className="center">You are a Mindeater!</h1>
      <Image
        src={resource('images/antagTips/intruder.gif')}
        className="center"
        width="64"
        height="64"
      />
      <p>
        1. You start off intangible and can choose to become tangible once at a
        location you pick. You get 3 lives, and will revert to an intangible
        state upon death.
      </p>
      <p>
        2. Your goal is to absorb brain power from crew members! Use your
        ability Brain Drain to do so, which will award you with Brain. Spend
        Brain to cast your abilities.
      </p>
      <p>
        3. You cloak while in darkness. Being in light for too long, attacking,
        or using certain abilities will reveal you. A visibility indicator next
        to you shows if you are visible or not.
      </p>
      <p>
        4. Your basic attack is a ranged attack that slows down those hit and
        prevents them from running.
      </p>
      <p>
        5. Use your stealth and your Disguise ability to sneakily drain Brain
        from the crew.
      </p>
      <p>This is a work in progress antag and will not be found on the wiki.</p>
    </div>
  ),
};
